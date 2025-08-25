#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Simple Terraform Deployment${NC}"
echo ""

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform not installed. Install with: brew install terraform${NC}"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured. Run: aws configure${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites OK${NC}"
}

# Deploy function
deploy() {
    echo -e "${BLUE}Deploying infrastructure...${NC}"
    
    cd terraform/environments/dev
    
    # Check terraform.tfvars
    if grep -q "REPLACE_WITH_YOUR_PUBLIC_KEY_CONTENT" terraform.tfvars; then
        echo -e "${RED}❌ Please update your public key in terraform.tfvars${NC}"
        echo "Run ./setup-local.sh to get your public key"
        exit 1
    fi
    
    # Deploy
    terraform init
    terraform validate
    terraform plan
    
    read -p "Apply this plan? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        terraform apply -auto-approve
        
        echo -e "${GREEN}🎉 Deployment complete!${NC}"
        echo ""
        terraform output
        
    else
        echo -e "${YELLOW}Deployment cancelled${NC}"
    fi
}

# Main execution
if [ ! -d "terraform/environments/dev" ]; then
    echo -e "${RED}❌ Run from project root directory${NC}"
    exit 1
fi

check_prerequisites
deploy

echo ""
echo -e "${GREEN}✅ Done! Check outputs above for access information${NC}"