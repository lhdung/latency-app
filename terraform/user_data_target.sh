#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install Nginx
apt-get install -y nginx

# Create a custom HTML page with server info
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Target Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .status { color: #28a745; font-weight: bold; }
        .info { background: #e9ecef; padding: 15px; margin: 20px 0; border-radius: 4px; }
        pre { background: #f8f9fa; padding: 10px; border-radius: 4px; overflow-x: auto; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #fff; border: 1px solid #ddd; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 Target Server</h1>
        <p class="status">✅ Server is running and reachable!</p>
        
        <div class="info">
            <h3>Server Information:</h3>
            <ul>
                <li><strong>Purpose:</strong> Target server for latency monitoring</li>
                <li><strong>HTTP Port:</strong> 80</li>
                <li><strong>HTTPS Port:</strong> 443 (with self-signed cert)</li>
                <li><strong>OS:</strong> Ubuntu 22.04 LTS</li>
                <li><strong>Web Server:</strong> Nginx</li>
            </ul>
        </div>

        <div class="info">
            <h3>Test Endpoints:</h3>
            <ul>
                <li><a href="/status">/status</a> - JSON status response</li>
                <li><a href="/health">/health</a> - Health check endpoint</li>
                <li><a href="/info">/info</a> - Server information</li>
                <li><a href="/metrics">/metrics</a> - Basic server metrics</li>
            </ul>
        </div>

        <div class="info">
            <h3>Real-time Metrics:</h3>
            <div class="metric">
                <strong>Current Time:</strong><br/>
                <span id="timestamp"></span>
            </div>
            <div class="metric">
                <strong>Response Time:</strong><br/>
                <span id="response-time">Measuring...</span>
            </div>
        </div>

        <div class="info">
            <h3>Connection Test:</h3>
            <p>This server is designed to be monitored by the latency monitor application.</p>
            <p>The monitor measures TCP connection time to port 80 of this server.</p>
        </div>
    </div>

    <script>
        function updateTime() {
            const start = performance.now();
            document.getElementById('timestamp').textContent = new Date().toISOString();
            const end = performance.now();
            document.getElementById('response-time').textContent = (end - start).toFixed(2) + ' ms';
        }
        updateTime();
        setInterval(updateTime, 1000);
    </script>
</body>
</html>
EOF

# Create Nginx configuration for target server
cat > /etc/nginx/sites-available/target-server << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html;
    
    server_name _;
    
    # Main page
    location / {
        try_files $uri $uri/ =404;
    }
    
    # JSON status endpoint
    location = /status {
        default_type application/json;
        access_log off;
        return 200 '{"status":"ok","service":"target-server","timestamp":"$time_iso8601","uptime_seconds":$msec,"server":"nginx","version":"1.0.0","purpose":"latency_monitoring_target"}';
        add_header Access-Control-Allow-Origin *;
    }
    
    # Health check endpoint
    location = /health {
        default_type application/json;
        access_log off;
        return 200 '{"health":"healthy","timestamp":"$time_iso8601","server":"target-server","checks":{"nginx":"running","disk":"ok","memory":"ok"},"purpose":"latency_monitoring_target"}';
        add_header Access-Control-Allow-Origin *;
    }
    
    # Server info endpoint
    location = /info {
        default_type application/json;
        access_log off;
        return 200 '{"server_info":{"timestamp":"$time_iso8601","server_name":"target-server","nginx_version":"$nginx_version","purpose":"latency_monitoring_target","ports":[80,443]}}';
        add_header Access-Control-Allow-Origin *;
    }
    
    # Basic metrics endpoint for monitoring
    location = /metrics {
        default_type text/plain;
        access_log off;
        return 200 '# HELP target_server_info Target server information
# TYPE target_server_info gauge
target_server_info{purpose="latency_monitoring_target",server="nginx"} 1
# HELP target_server_uptime_ms Server uptime in milliseconds
# TYPE target_server_uptime_ms counter
target_server_uptime_ms $msec
# HELP target_server_requests_total Total number of requests
# TYPE target_server_requests_total counter
target_server_requests_total{method="GET"} 1
';
    }
    
    # Logging
    access_log /var/log/nginx/target-server.access.log;
    error_log /var/log/nginx/target-server.error.log;
}
EOF

# Generate self-signed SSL certificate for HTTPS
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx-selfsigned.key \
    -out /etc/nginx/ssl/nginx-selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=target-server"

# Create HTTPS server configuration
cat > /etc/nginx/sites-available/target-server-ssl << 'EOF'
server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    
    root /var/www/html;
    index index.html;
    
    server_name _;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/nginx-selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Main page
    location / {
        try_files $uri $uri/ =404;
    }
    
    # JSON endpoints with HTTPS indicator
    location = /status {
        default_type application/json;
        access_log off;
        return 200 '{"status":"ok","service":"target-server-ssl","timestamp":"$time_iso8601","protocol":"https","server":"nginx","version":"1.0.0","purpose":"latency_monitoring_target"}';
        add_header Access-Control-Allow-Origin *;
    }
    
    location = /health {
        default_type application/json;
        access_log off;
        return 200 '{"health":"healthy","timestamp":"$time_iso8601","protocol":"https","server":"target-server","ssl":"enabled","purpose":"latency_monitoring_target"}';
        add_header Access-Control-Allow-Origin *;
    }
    
    # Logging
    access_log /var/log/nginx/target-server-ssl.access.log;
    error_log /var/log/nginx/target-server-ssl.error.log;
}
EOF

# Remove default Nginx site and enable our sites
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/target-server /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/target-server-ssl /etc/nginx/sites-enabled/

# Test nginx configuration
nginx -t

# Start and enable Nginx
systemctl start nginx
systemctl enable nginx

# Create a monitoring script for the target server
cat > /home/ubuntu/check-target.sh << 'EOF'
#!/bin/bash
echo "=== Target Server Status ==="
sudo systemctl status nginx --no-pager

echo -e "\n=== HTTP Test ==="
curl -s http://localhost/status | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null || echo "HTTP service not ready"

echo -e "\n=== HTTPS Test ==="
curl -s -k https://localhost/status | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null || echo "HTTPS service not ready"

echo -e "\n=== Port Check ==="
ss -tlnp | grep -E ':(80|443)\s'

echo -e "\n=== Recent Access Logs (last 5 lines) ==="
sudo tail -5 /var/log/nginx/target-server.access.log 2>/dev/null || echo "No access logs yet"

echo -e "\n=== Server Info ==="
echo "Server Purpose: Latency Monitoring Target"
echo "Listening on: HTTP (80), HTTPS (443)"
echo "Status: $(systemctl is-active nginx)"
EOF

chmod +x /home/ubuntu/check-target.sh
chown ubuntu:ubuntu /home/ubuntu/check-target.sh

# Create log rotation for our logs
cat > /etc/logrotate.d/target-server << 'EOF'
/var/log/nginx/target-server*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        systemctl reload nginx
    endscript
}
EOF

echo "Target server setup completed!" > /home/ubuntu/setup-complete.log
echo "HTTP: Port 80" >> /home/ubuntu/setup-complete.log
echo "HTTPS: Port 443" >> /home/ubuntu/setup-complete.log
echo "Purpose: Latency monitoring target" >> /home/ubuntu/setup-complete.log
