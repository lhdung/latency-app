#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Network Latency Monitor Deployment Script ===${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "terraform/main.tf" ]; then
    echo -e "${RED}Error: terraform/main.tf not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Check if Docker Hub credentials are set
if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
    echo -e "${YELLOW}Warning: DOCKER_USERNAME and DOCKER_PASSWORD environment variables not set.${NC}"
    echo -e "${YELLOW}Docker image will be pulled from public registry only.${NC}"
    echo ""
fi

# Step 1: Build and push Docker image (optional)
read -p "Do you want to build and push a new Docker image? (y/N): " build_image
if [[ $build_image =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Step 1: Building and pushing Docker image...${NC}"
    
    # Get git commit hash for tagging
    GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
    IMAGE_TAG="lhdung/latency-app:$GIT_SHA"
    
    echo "Building image: $IMAGE_TAG"
    docker build -t "$IMAGE_TAG" .
    docker tag "$IMAGE_TAG" "lhdung/latency-app:latest"
    
    if [ ! -z "$DOCKER_USERNAME" ] && [ ! -z "$DOCKER_PASSWORD" ]; then
        echo "Pushing to Docker Hub..."
        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
        docker push "$IMAGE_TAG"
        docker push "lhdung/latency-app:latest"
        echo -e "${GREEN}✓ Docker image pushed successfully${NC}"
        
        # Use the newly built image
        export TF_VAR_docker_image="$IMAGE_TAG"
    else
        echo -e "${YELLOW}Skipping push (no Docker credentials)${NC}"
    fi
    echo ""
else
    echo -e "${YELLOW}Skipping Docker build. Using existing image.${NC}"
    echo ""
fi

# Step 2: Check Terraform configuration
echo -e "${BLUE}Step 2: Checking Terraform configuration...${NC}"
cd terraform

if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}terraform.tfvars not found. Please create it from terraform.tfvars.example${NC}"
    echo "Required variables:"
    echo "- public_key (SSH public key)"
    echo "- ssh_allowed_cidr (your IP address)"
    echo ""
    read -p "Do you want to continue with default values? (y/N): " continue_default
    if [[ ! $continue_default =~ ^[Yy]$ ]]; then
        echo -e "${RED}Please create terraform.tfvars and run again.${NC}"
        exit 1
    fi
fi

# Step 3: Deploy infrastructure
echo -e "${BLUE}Step 3: Deploying infrastructure with Terraform...${NC}"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan deployment
echo "Planning deployment..."
terraform plan

# Confirm deployment
echo ""
read -p "Do you want to apply these changes? (y/N): " apply_changes
if [[ ! $apply_changes =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
fi

# Apply deployment
echo "Applying Terraform configuration..."
terraform apply -auto-approve

# Get outputs
echo -e "${GREEN}✓ Infrastructure deployed successfully!${NC}"
echo ""

# Step 4: Display results
echo -e "${BLUE}Step 4: Deployment Summary${NC}"
echo ""

# Get the outputs
LATENCY_MONITOR_IP=$(terraform output -raw latency_monitor_public_ip)
TARGET_SERVER_IP=$(terraform output -raw target_server_public_ip)
MONITORING_URL=$(terraform output -raw latency_api_endpoint)
TARGET_URL=$(terraform output -raw target_server_http_endpoint)

echo -e "${GREEN}🎯 Deployment Complete!${NC}"
echo ""
echo "📊 Latency Monitor:"
echo "   IP: $LATENCY_MONITOR_IP"
echo "   URL: http://$LATENCY_MONITOR_IP:8000"
echo "   API: $MONITORING_URL"
echo ""
echo "🎯 Target Server:"
echo "   IP: $TARGET_SERVER_IP"
echo "   URL: $TARGET_URL"
echo ""
echo "🔗 Target Configuration:"
echo "   Monitor → Target: $TARGET_SERVER_IP:80"
echo ""

# Step 5: Wait for services and verify
echo -e "${BLUE}Step 5: Waiting for services to start...${NC}"
echo "This may take 2-3 minutes for all services to be ready."
echo ""

# Wait for target server
echo "Waiting for target server to be ready..."
for i in {1..30}; do
    if curl -s --connect-timeout 3 "$TARGET_URL/status" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Target server is ready${NC}"
        break
    fi
    echo -n "."
    sleep 10
done
echo ""

# Wait for latency monitor
echo "Waiting for latency monitor to be ready..."
for i in {1..30}; do
    if curl -s --connect-timeout 3 "http://$LATENCY_MONITOR_IP:8000/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Latency monitor is ready${NC}"
        break
    fi
    echo -n "."
    sleep 10
done
echo ""

# Step 6: Verification
echo -e "${BLUE}Step 6: Verifying deployment...${NC}"
echo ""

echo "Testing target server:"
curl -s "$TARGET_URL/status" | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin), indent=2))" || echo "Target server not responding"
echo ""

echo "Testing latency monitor:"
curl -s "$MONITORING_URL" | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin), indent=2))" || echo "Latency monitor not responding"
echo ""

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Visit: $MONITORING_URL"
echo "2. Check metrics: http://$LATENCY_MONITOR_IP:8000/metrics"
echo "3. SSH to monitor: ssh -i ~/.ssh/latency-monitor ubuntu@$LATENCY_MONITOR_IP"
echo "4. SSH to target: ssh -i ~/.ssh/latency-monitor ubuntu@$TARGET_SERVER_IP"
echo ""
echo "To destroy the infrastructure later:"
echo "cd terraform && terraform destroy"
