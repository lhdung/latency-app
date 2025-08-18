# Network Latency Monitor

A complete solution for monitoring network latency between servers, featuring a FastAPI application, automated CI/CD, and Infrastructure-as-Code deployment.

## 🎯 **Project Overview**

This project implements the requirements:
> *"Provision two virtual machines in a cloud environment and deploy a simple application on one of them that measures and exposes the network latency to the second server."*

**Key Features:**
- 🌐 **FastAPI Application**: Measures TCP connect latency between servers
- 🐳 **Docker Containerization**: Easy deployment and scaling
- 🏗️ **Infrastructure-as-Code**: Terraform for AWS deployment
- 🔄 **CI/CD Pipeline**: Automated builds with GitHub Actions
- 📊 **Monitoring**: Prometheus metrics and health checks
- 🚀 **Complete Automation**: One-command deployment

## 📁 **Project Structure**

```
├── app/
│   └── main.py                     # FastAPI application
├── terraform/
│   ├── main.tf                     # AWS infrastructure
│   ├── variables.tf                # Configuration variables
│   ├── outputs.tf                  # Deployment outputs
│   ├── user_data_monitor.sh        # Monitor server setup
│   ├── user_data_target.sh         # Target server setup
│   ├── terraform.tfvars.example    # Example configuration
│   └── README.md                   # Infrastructure guide
├── .github/workflows/
│   ├── build-and-push.yml          # Main CI/CD pipeline
│   └── build-and-push-simple.yml   # Simplified alternative
├── Dockerfile                      # Container definition
├── requirements.txt                # Python dependencies
├── deploy.sh                       # One-command deployment
├── .gitignore                      # Git ignore rules
└── README.md                       # This file
```

## 🚀 **Quick Start**

### **Option 1: Complete Deployment (Recommended)**
```bash
# 1. Clone and configure
git clone https://github.com/lhdung/latency-app.git
cd latency-app

# 2. Setup SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/latency-monitor

# 3. Configure Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your SSH public key

# 4. Deploy everything
./deploy.sh
```

### **Option 2: Docker Only (Local Testing)**
```bash
# Pull from Docker Hub
docker pull lhdung/latency-app:latest

# Run with target
docker run -p 8000:8000 \
  -e TARGET_HOST=google.com \
  -e TARGET_PORT=443 \
  lhdung/latency-app:latest

# Visit: http://localhost:8000/latency
```

## 🏗️ **Architecture**

### **AWS Infrastructure**
```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS VPC (10.0.0.0/16)                 │
│                                                                 │
│  ┌──────────────────────┐        ┌──────────────────────┐      │
│  │   Public Subnet A    │        │   Public Subnet B    │      │
│  │   (10.0.1.0/24)      │        │   (10.0.2.0/24)      │      │
│  │                      │        │                      │      │
│  │  ┌─────────────────┐ │        │  ┌─────────────────┐ │      │
│  │  │ Monitor Server  │ │───────▶│  │  Target Server  │ │      │
│  │  │   (FastAPI)     │ │ TCP:80 │  │    (Nginx)      │ │      │
│  │  │   Port 8000     │ │        │  │   Port 80/443   │ │      │
│  │  └─────────────────┘ │        │  └─────────────────┘ │      │
│  └──────────────────────┘        └──────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

### **Application Flow**
```
┌─────────────────┐    TCP Connect    ┌─────────────────┐
│ Monitor Server  │ ─────────────────▶ │ Target Server   │
│ (FastAPI App)   │   Every 5 sec     │ (Nginx)         │
│ Docker Container│   Measure time    │ Static Web      │
└─────────────────┘                   └─────────────────┘
         │                                     ▲
         ▼                                     │
┌─────────────────┐                           │
│ HTTP Endpoints  │                           │
│ /latency        │◀──────────────────────────┘
│ /metrics        │    User/Monitoring Access
│ /health         │
└─────────────────┘
```

## 📊 **API Endpoints**

### **Monitor Server (Port 8000)**
- `GET /` - Service information and available endpoints
- `GET /latency` - Latest latency measurement in JSON format
- `GET /metrics` - Prometheus-compatible metrics
- `GET /health` - Health check status

**Example Response (`/latency`):**
```json
{
  "target_host": "192.168.1.100",
  "target_port": 80,
  "check_interval_seconds": 5.0,
  "connect_timeout_seconds": 3.0,
  "latest_latency_ms": 24.5,
  "last_success_unix": 1704067200.145,
  "last_error_message": null,
  "last_error_unix": null
}
```

### **Target Server (Port 80/443)**
- `GET /` - Server information page
- `GET /status` - JSON status response
- `GET /health` - Health check endpoint
- `GET /info` - Server details
- `GET /metrics` - Basic server metrics

## ⚙️ **Configuration**

### **Environment Variables**
| Variable | Default | Description |
|----------|---------|-------------|
| `TARGET_HOST` | *Required* | Hostname/IP to measure latency to |
| `TARGET_PORT` | `80` | Port to connect to |
| `CHECK_INTERVAL_SECONDS` | `5` | How often to measure latency |
| `CONNECT_TIMEOUT_SECONDS` | `3` | Connection timeout |
| `PORT` | `8000` | HTTP server port |

### **Terraform Variables**
| Variable | Description | Required |
|----------|-------------|----------|
| `public_key` | SSH public key for EC2 access | **Yes** |
| `aws_region` | AWS region for deployment | No |
| `instance_type` | EC2 instance type | No |
| `docker_image` | Docker image to deploy | No |

## 🔄 **CI/CD Pipeline**

The project uses GitHub Actions for automated building and publishing:

### **Triggers**
- Push to `main`/`develop` branches
- Pull requests to `main`
- Changes to app code, Dockerfile, or requirements

### **Process**
1. **Build**: Multi-architecture Docker images (AMD64, ARM64)
2. **Test**: Security scanning with Trivy
3. **Push**: To Docker Hub with tags:
   - `lhdung/latency-app:latest`
   - `lhdung/latency-app:<commit-sha>`

### **Setup CI/CD**
Add these secrets to your GitHub repository:
```
DOCKER_USERNAME: lhdung
DOCKER_PASSWORD: <your-docker-hub-token>
```

## 🛠️ **Development**

### **Local Development**
```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
export TARGET_HOST=google.com
export TARGET_PORT=443
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### **Docker Development**
```bash
# Build image
docker build -t latency-monitor .

# Run with target
docker run -p 8000:8000 \
  -e TARGET_HOST=1.1.1.1 \
  -e TARGET_PORT=53 \
  latency-monitor
```

## 🚀 **Deployment Options**

### **1. Full AWS Deployment**
- ✅ Two EC2 instances in separate subnets
- ✅ Automatic target server configuration
- ✅ Security groups and networking
- ✅ Elastic IPs for stable access
- ✅ Cloud-init automation

```bash
cd terraform/
terraform init && terraform apply
```

### **2. Docker Compose (Local)**
```bash
# For local testing with mock target
docker-compose up
```

### **3. Manual Docker Run**
```bash
docker run -p 8000:8000 \
  -e TARGET_HOST=your-target-server \
  -e TARGET_PORT=80 \
  lhdung/latency-app:latest
```

## 📈 **Monitoring & Metrics**

### **Prometheus Metrics**
```
# HELP network_latency_ms Latest measured TCP connect latency
network_latency_ms{target_host="192.168.1.100",target_port="80"} 24.5

# HELP network_latency_success_total Number of successful measurements
network_latency_success_total{target_host="192.168.1.100",target_port="80"} 142

# HELP network_latency_failure_total Number of failed measurements  
network_latency_failure_total{target_host="192.168.1.100",target_port="80"} 3
```

### **Health Monitoring**
- Built-in health checks at `/health`
- Service status monitoring scripts
- Automatic service restart on failure
- Comprehensive logging

## 💰 **Cost Estimation**

**AWS Deployment (Monthly):**
- 2 × t3.micro instances: ~$16 (Free Tier eligible)
- 2 × Elastic IPs: ~$7
- Data Transfer: Minimal (internal VPC)
- **Total**: ~$23/month (~$9 with Free Tier)

## 🔧 **Troubleshooting**

### **Common Issues**

**Service not responding:**
```bash
# Check service status
ssh -i ~/.ssh/latency-monitor ubuntu@MONITOR_IP
sudo systemctl status latency-monitor
```

**Wrong target being monitored:**
```bash
# Verify target configuration
curl http://MONITOR_IP:8000/latency | grep target_host
```

**Docker build issues:**
```bash
# Check GitHub Actions logs
# Visit: https://github.com/lhdung/latency-app/actions
```

### **Logs and Debugging**
```bash
# Monitor service logs
sudo journalctl -u latency-monitor.service -f

# Target server logs
sudo tail -f /var/log/nginx/target-server.access.log

# Docker container logs
sudo docker logs latency-monitor
```

## 🔐 **Security**

- ✅ **VPC Isolation**: Servers communicate within private network
- ✅ **Security Groups**: Minimal port exposure
- ✅ **SSH Key Authentication**: No password access
- ✅ **HTTPS Support**: Self-signed certificates for target server
- ✅ **Docker Security**: Non-root container execution

## 📚 **Documentation**

- [Infrastructure Guide](terraform/README.md) - Detailed Terraform documentation
- [GitHub Actions](https://github.com/lhdung/latency-app/actions) - CI/CD pipeline
- [Docker Hub](https://hub.docker.com/r/lhdung/latency-app) - Container registry

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make changes and test
4. Submit a pull request

## 📄 **License**

MIT License - see LICENSE file for details.

---

## 🎯 **Summary**

This project provides a complete, production-ready solution for network latency monitoring between servers, featuring:

- **🏗️ Infrastructure-as-Code** with Terraform
- **🐳 Containerized Application** with Docker
- **🔄 Automated CI/CD** with GitHub Actions  
- **📊 Monitoring & Metrics** with Prometheus
- **🚀 One-Command Deployment** with automation scripts

Perfect for DevOps interviews, portfolio projects, or production monitoring! 🌟