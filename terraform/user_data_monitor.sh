#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install Docker
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Pull the latency monitor Docker image
docker pull ${docker_image}

# Create systemd service for latency monitor
cat > /etc/systemd/system/latency-monitor.service << 'EOF'
[Unit]
Description=Network Latency Monitor
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=5
User=root
Environment=TARGET_HOST=${target_host}
Environment=TARGET_PORT=${target_port}
Environment=CHECK_INTERVAL_SECONDS=5
Environment=CONNECT_TIMEOUT_SECONDS=3
ExecStartPre=-/usr/bin/docker stop latency-monitor
ExecStartPre=-/usr/bin/docker rm latency-monitor
ExecStart=/usr/bin/docker run --rm --name latency-monitor \
    -p 8000:8000 \
    -e TARGET_HOST=${target_host} \
    -e TARGET_PORT=${target_port} \
    -e CHECK_INTERVAL_SECONDS=5 \
    -e CONNECT_TIMEOUT_SECONDS=3 \
    ${docker_image}
ExecStop=/usr/bin/docker stop latency-monitor
TimeoutStartSec=300
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable latency-monitor.service

# Wait for target server to be ready (it might still be booting)
echo "Waiting for target server ${target_host}:${target_port} to be ready..."
for i in {1..60}; do
    if timeout 3 bash -c "</dev/tcp/${target_host}/${target_port}"; then
        echo "Target server is ready!"
        break
    fi
    echo "Attempt $i: Target server not ready yet, waiting 10 seconds..."
    sleep 10
done

# Start the latency monitor service
systemctl start latency-monitor.service

# Create a simple health check script
cat > /home/ubuntu/check-service.sh << 'EOF'
#!/bin/bash
echo "=== Latency Monitor Service Status ==="
sudo systemctl status latency-monitor.service --no-pager

echo -e "\n=== Docker Container Status ==="
sudo docker ps | grep latency-monitor

echo -e "\n=== Test Endpoints ==="
echo "Testing /latency endpoint:"
curl -s http://localhost:8000/latency | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null || echo "Service not ready yet"

echo -e "\nTesting /health endpoint:"
curl -s http://localhost:8000/health | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null || echo "Service not ready yet"

echo -e "\n=== Service Logs (last 10 lines) ==="
sudo journalctl -u latency-monitor.service -n 10 --no-pager
EOF

chmod +x /home/ubuntu/check-service.sh
chown ubuntu:ubuntu /home/ubuntu/check-service.sh

# Create an update script for easy app updates
cat > /home/ubuntu/update-app.sh << 'EOF'
#!/bin/bash
echo "Updating latency monitor application..."

# Pull latest image
sudo docker pull ${docker_image}

# Restart service to use new image
sudo systemctl restart latency-monitor.service

echo "Update complete! Check status with ./check-service.sh"
EOF

chmod +x /home/ubuntu/update-app.sh
chown ubuntu:ubuntu /home/ubuntu/update-app.sh

echo "Latency Monitor setup completed!" > /home/ubuntu/setup-complete.log
echo "Target: ${target_host}:${target_port}" >> /home/ubuntu/setup-complete.log
echo "Docker Image: ${docker_image}" >> /home/ubuntu/setup-complete.log
