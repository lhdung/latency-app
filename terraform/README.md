# Infrastructure as Code - AWS Deployment

This Terraform configuration provisions two EC2 instances in AWS:
1. **Latency Monitor Server** - Runs the FastAPI application that measures latency
2. **Target Server** - Simple web server that the monitor measures latency to

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS VPC (10.0.0.0/16)                 │
│                                                                 │
│  ┌──────────────────────┐        ┌──────────────────────┐      │
│  │   Public Subnet A    │        │   Public Subnet B    │      │
│  │   (10.0.1.0/24)      │        │   (10.0.2.0/24)      │      │
│  │                      │        │                      │      │
│  │  ┌─────────────────┐ │        │  ┌─────────────────┐ │      │
│  │  │ Latency Monitor │ │───────▶│  │  Target Server  │ │      │
│  │  │   (FastAPI)     │ │ TCP:80 │  │    (Nginx)      │ │      │
│  │  │   Port 8000     │ │        │  │   Port 80/443   │ │      │
│  │  │                 │ │        │  │                 │ │      │
│  │  └─────────────────┘ │        │  └─────────────────┘ │      │
│  └──────────────────────┘        └──────────────────────┘      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Key Changes from Generic Setup:**
- ✅ **Monitor measures YOUR target server** (not Google)
- ✅ **Target server IP automatically configured** during deployment
- ✅ **Uses your Docker image** from `lhdung/latency-app`
- ✅ **Proper server-to-server monitoring** within VPC

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (>= 1.0)
3. **SSH key pair** for EC2 access
4. **Docker image** available at `lhdung/latency-app:latest`

### Generate SSH Key Pair

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/latency-monitor
```

## Quick Deployment

### **Option 1: Automated Script (Recommended)**
```bash
# From project root
./deploy.sh
```

This script will:
1. Optionally build and push Docker image
2. Deploy infrastructure with Terraform
3. Wait for services to be ready
4. Verify the deployment works

### **Option 2: Manual Deployment**

1. **Navigate to terraform directory**:
   ```bash
   cd terraform/
   ```

2. **Copy and customize variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your public key and settings
   ```

3. **Initialize and deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Get connection details**:
   ```bash
   terraform output
   ```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | `us-east-1` | No |
| `environment` | Environment name | `dev` | No |
| `instance_type` | EC2 instance type | `t3.micro` | No |
| `public_key` | SSH public key for EC2 access | - | **Yes** |
| `ssh_allowed_cidr` | CIDR blocks allowed for SSH | `["0.0.0.0/0"]` | No |
| `docker_image` | Docker image for latency monitor | `lhdung/latency-app:latest` | No |

## Outputs

After deployment, Terraform provides:

- **IP Addresses**: Public IPs for both servers
- **Endpoints**: Direct URLs to access services
- **SSH Commands**: Ready-to-use SSH connection commands
- **Monitoring URLs**: Links to latency data and metrics
- **Verification Commands**: curl commands to test everything

## Services Deployed

### Latency Monitor Server
- **FastAPI application** running in Docker
- **Automatically configured** to monitor the target server
- **Endpoints**:
  - `http://IP:8000/` - Service info
  - `http://IP:8000/latency` - JSON latency data
  - `http://IP:8000/metrics` - Prometheus metrics
  - `http://IP:8000/health` - Health check
- **Measures TCP connect time** to target server every 5 seconds

### Target Server  
- **Nginx web server** with monitoring-friendly endpoints
- **Endpoints**:
  - `http://IP/` - Main page with server info
  - `http://IP/status` - JSON status
  - `http://IP/health` - Health check
  - `http://IP/info` - Server information
  - `http://IP/metrics` - Basic server metrics
  - `https://IP/` - HTTPS version (self-signed cert)

## Post-Deployment Verification

### **Automatic Verification (if using deploy.sh)**
The deployment script automatically tests all endpoints.

### **Manual Verification**

1. **Check latency monitor**:
   ```bash
   curl http://LATENCY_MONITOR_IP:8000/latency
   ```
   Should show latency to YOUR target server, not Google!

2. **Check target server**:
   ```bash
   curl http://TARGET_SERVER_IP/status
   ```

3. **Verify monitoring is working**:
   ```bash
   # Check that target_host matches your target server IP
   curl http://LATENCY_MONITOR_IP:8000/latency | grep target_host
   ```

4. **SSH to servers**:
   ```bash
   ssh -i ~/.ssh/latency-monitor ubuntu@LATENCY_MONITOR_IP
   ssh -i ~/.ssh/latency-monitor ubuntu@TARGET_SERVER_IP
   ```

## How It Works

1. **Infrastructure Creation**: Terraform creates VPC, subnets, security groups, and EC2 instances
2. **Target Server Setup**: Cloud-init installs Nginx and configures monitoring endpoints
3. **Monitor Server Setup**: Cloud-init pulls your Docker image and configures it to monitor the target server
4. **Automatic Configuration**: Target server IP is automatically passed to the monitor app
5. **Service Startup**: Both services start automatically and begin monitoring

## Monitoring Flow

```
┌─────────────────┐    TCP Connect    ┌─────────────────┐
│ Monitor Server  │ ─────────────────▶ │ Target Server   │
│ (FastAPI App)   │   Every 5 sec     │ (Nginx)         │
│ Port 8000       │   Measure time    │ Port 80         │
└─────────────────┘                   └─────────────────┘
         │                                     ▲
         ▼                                     │
┌─────────────────┐                           │
│ HTTP Endpoints  │                           │
│ /latency        │                           │
│ /metrics        │                           │
│ /health         │                           │
└─────────────────┘                           │
         │                                     │
         ▼                                     │
┌─────────────────┐                           │
│ Your Browser/   │ ──────────────────────────┘
│ Monitoring Tool │    (Optional verification)
└─────────────────┘
```

## Cleanup

To destroy all resources:
```bash
cd terraform
terraform destroy
```

## Security Notes

- **SSH Access**: Restrict `ssh_allowed_cidr` to your IP address
- **VPC Isolation**: Servers communicate within private VPC
- **Security Groups**: Only necessary ports are opened
- **No SSL Required**: Internal VPC communication is secure by default

## Cost Estimation

With default `t3.micro` instances:
- **2 × t3.micro**: ~$16/month (AWS Free Tier eligible)
- **2 × Elastic IPs**: ~$7/month  
- **Data Transfer**: Minimal cost (internal VPC traffic is free)
- **Total**: ~$23/month (or ~$9/month with Free Tier)

## Troubleshooting

### **Services not responding**:
```bash
# SSH to servers and check status
ssh -i ~/.ssh/latency-monitor ubuntu@MONITOR_IP
sudo systemctl status latency-monitor

ssh -i ~/.ssh/latency-monitor ubuntu@TARGET_IP
sudo systemctl status nginx
```

### **Wrong target being monitored**:
```bash
# Check target configuration
curl http://MONITOR_IP:8000/latency | grep target_host
# Should show your target server IP, not google.com
```

### **View service logs**:
```bash
# Monitor server
sudo journalctl -u latency-monitor.service -f

# Target server
sudo tail -f /var/log/nginx/target-server.access.log
```

### **Update application**:
```bash
# SSH to monitor server
ssh -i ~/.ssh/latency-monitor ubuntu@MONITOR_IP
./update-app.sh
```

The infrastructure is designed to automatically configure server-to-server latency monitoring without any manual configuration! 🚀
