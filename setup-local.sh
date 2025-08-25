#!/bin/bash
set -e

echo "🔧 Simple Setup for Terraform Deployment"
echo ""

# Generate SSH key
if [ ! -f ~/.ssh/latency-monitor ]; then
    echo "📋 Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/latency-monitor -N ""
    echo "✅ SSH key generated"
else
    echo "✅ SSH key already exists"
fi

# Show public key
echo ""
echo "📋 Your SSH public key:"
echo "----------------------------------------"
cat ~/.ssh/latency-monitor.pub
echo "----------------------------------------"

# Show current IP
echo ""
echo "📋 Your current IP (optional for security):"
curl -s ifconfig.me
echo ""

# Check terraform.tfvars
TFVARS="terraform/environments/dev/terraform.tfvars"
echo ""
if [ -f "$TFVARS" ]; then
    if grep -q "REPLACE_WITH_YOUR_PUBLIC_KEY_CONTENT" "$TFVARS"; then
        echo "⚠️  Please update the public_key in $TFVARS"
    else
        echo "✅ Configuration looks ready"
    fi
else
    echo "❌ $TFVARS not found"
fi

echo ""
echo "🚀 Next steps:"
echo "1. Update public_key in $TFVARS"
echo "2. Run: ./deploy-local.sh"
echo ""