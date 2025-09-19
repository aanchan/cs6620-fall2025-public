#!/bin/bash

# server-setup.sh - Initial server configuration for Speech Labeling Interface
# Week 2: SSH Deployment Lab

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Setting up server for Speech Labeling Interface${NC}"
echo -e "${BLUE}📚 CS6620 Week 2: SSH Deployment Lab${NC}"

# Check if running as ec2-user
if [ "$USER" != "ec2-user" ]; then
    echo -e "${YELLOW}⚠️  This script should be run as ec2-user${NC}"
fi

# Update system packages
echo -e "${YELLOW}📦 Updating system packages...${NC}"
sudo yum update -y

# Install required packages
echo -e "${YELLOW}🛠️  Installing required packages...${NC}"
sudo yum install -y curl --allowerasing
sudo yum install -y python3 python3-pip git wget

# Install Python dependencies
echo -e "${YELLOW}🐍 Installing Python dependencies...${NC}"
pip3 install --user flask flask-cors pydub gunicorn

# Add local bin to PATH if not already there
if ! echo $PATH | grep -q "/home/ec2-user/.local/bin"; then
    echo 'export PATH="/home/ec2-user/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="/home/ec2-user/.local/bin:$PATH"
fi

# Create application directory
echo -e "${YELLOW}📁 Creating application directories...${NC}"
sudo mkdir -p /opt/speech-labeling
sudo chown ec2-user:ec2-user /opt/speech-labeling

# Create data directories
sudo mkdir -p /opt/audio /opt/data
sudo chown ec2-user:ec2-user /opt/audio /opt/data

# Create logs directory
sudo mkdir -p /var/log/speech-labeling
sudo chown ec2-user:ec2-user /var/log/speech-labeling





# Display setup summary
echo ""
echo -e "${GREEN}🎉 Server setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 Setup Summary:${NC}"
echo -e "${GREEN}   ✅ System packages updated${NC}"
echo -e "${GREEN}   ✅ Python and dependencies installed${NC}"
echo -e "${GREEN}   ✅ Application directories created${NC}"
echo -e "${GREEN}   ✅ Gunicorn WSGI server installed${NC}"
echo ""

echo -e "${YELLOW}📁 Directory Structure:${NC}"
echo -e "${BLUE}   Application: /opt/speech-labeling${NC}"
echo -e "${BLUE}   Audio files: /opt/audio${NC}"
echo -e "${BLUE}   Data files: /opt/data${NC}"
echo -e "${BLUE}   Logs: /var/log/speech-labeling${NC}"
echo ""


echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Copy your application files to /opt/speech-labeling/"
echo "   cp -r ~/cs6620-educational-repo/* /opt/speech-labeling/"
echo ""
echo "2. Copy audio files to /opt/audio/ (optional)"
echo "3. Copy CSV data file to /opt/data/err-dataset.csv (optional)"
echo ""
echo "4. Start the application:"
echo "   cd /opt/speech-labeling"
echo "   ./start.sh"
echo ""
echo "5. Stop the application when done:"
echo "   ./stop.sh"
echo ""
echo "6. Access your app at: http://\$(curl -s ifconfig.me)"
echo ""

echo -e "${GREEN}🎓 Week 2 SSH Deployment Lab Setup Complete!${NC}"
