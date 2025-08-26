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
sudo yum install -y python3 python3-pip git curl wget

# Install nginx from Amazon Linux Extras
echo -e "${YELLOW}🌐 Installing nginx from Amazon Linux Extras...${NC}"
sudo amazon-linux-extras install -y nginx1

# Install Python dependencies
echo -e "${YELLOW}🐍 Installing Python dependencies...${NC}"
pip3 install --user flask flask-cors pydub

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

# Configure nginx
echo -e "${YELLOW}🌐 Configuring nginx...${NC}"
sudo mkdir -p /etc/nginx/conf.d
sudo tee /etc/nginx/conf.d/speech-labeling.conf > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    
    client_max_body_size 100M;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Test nginx configuration
sudo nginx -t

# Enable nginx service (don't start yet, wait for app deployment)
sudo systemctl enable nginx

# Create systemd service file for the application
echo -e "${YELLOW}⚙️  Creating systemd service...${NC}"
sudo tee /etc/systemd/system/speech-labeling.service > /dev/null <<EOF
[Unit]
Description=Speech Error Labeling Interface
After=network.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/speech-labeling
Environment=PATH=/home/ec2-user/.local/bin:/usr/local/bin:/usr/bin:/bin
Environment=DEFAULT_AUDIO_DIR=/opt/audio
Environment=DEFAULT_CSV_PATH=/opt/data/err-dataset.csv
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Create deployment script
echo -e "${YELLOW}📜 Creating deployment helper scripts...${NC}"
tee ./deploy-app.sh > /dev/null <<EOF
#!/bin/bash
# deploy-app.sh - Deploy the speech labeling application

echo "🚀 Deploying Speech Labeling Application"

# Copy application files from cloned repo to deployment directory
echo "📁 Copying application files..."
cp -r ~/cs6620-educational-repo/* /opt/speech-labeling/

# Navigate to application directory
cd /opt/speech-labeling

# Stop service if running
sudo systemctl stop speech-labeling 2>/dev/null || true

# Install/update Python dependencies
pip3 install --user -r requirements.txt

# Start the service
sudo systemctl start speech-labeling
sudo systemctl enable speech-labeling

# Start nginx
sudo systemctl start nginx

# Check service status
echo "📊 Service Status:"
sudo systemctl status speech-labeling --no-pager -l

echo ""
echo "🌐 Nginx Status:"
sudo systemctl status nginx --no-pager -l

echo ""
echo "✅ Deployment complete!"
echo "🔍 Access your application at: http://$(curl -s ifconfig.me)"
echo "🎛️  Labeling interface: http://$(curl -s ifconfig.me)/labeling"
EOF

chmod +x ./deploy-app.sh

# Create log monitoring script
tee ./monitor-logs.sh > /dev/null <<EOF
#!/bin/bash
# monitor-logs.sh - Monitor application and nginx logs

echo "📊 Monitoring Speech Labeling Application Logs"
echo "Press Ctrl+C to stop"
echo ""

# Show recent logs and follow new ones
echo "🔍 Application Logs:"
sudo journalctl -u speech-labeling -n 20 -f &
APP_PID=\$!

echo ""
echo "🌐 Nginx Access Logs:"
sudo tail -f /var/log/nginx/access.log &
NGINX_PID=\$!

# Wait for user interrupt
trap 'kill \$APP_PID \$NGINX_PID 2>/dev/null; exit' INT
wait
EOF

chmod +x ./monitor-logs.sh

# Display setup summary
echo ""
echo -e "${GREEN}🎉 Server setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 Setup Summary:${NC}"
echo -e "${GREEN}   ✅ System packages updated${NC}"
echo -e "${GREEN}   ✅ Python and dependencies installed${NC}"
echo -e "${GREEN}   ✅ Application directories created${NC}"
echo -e "${GREEN}   ✅ Nginx configured${NC}"
echo -e "${GREEN}   ✅ Systemd service created${NC}"
echo -e "${GREEN}   ✅ Helper scripts created${NC}"
echo ""

echo -e "${YELLOW}📁 Directory Structure:${NC}"
echo -e "${BLUE}   Application: /opt/speech-labeling${NC}"
echo -e "${BLUE}   Audio files: /opt/audio${NC}"
echo -e "${BLUE}   Data files: /opt/data${NC}"
echo -e "${BLUE}   Logs: /var/log/speech-labeling${NC}"
echo ""

echo -e "${YELLOW}🛠️  Helper Scripts:${NC}"
echo -e "${BLUE}   Deploy app: ~/deploy-app.sh${NC}"
echo -e "${BLUE}   Monitor logs: ~/monitor-logs.sh${NC}"
echo ""

echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Upload your application files to /opt/speech-labeling/ (from your local machine):"
echo "   scp -i ~/.ssh/my-ec2-key.pem -r . ec2-user@\$INSTANCE_IP:/opt/speech-labeling/"
echo ""
echo "2. Upload audio files to /opt/audio/ (from your local machine):"
echo "   scp -i ~/.ssh/my-ec2-key.pem -r audio-directory/* ec2-user@\$INSTANCE_IP:/opt/audio/"
echo ""
echo "3. Upload CSV data file (from your local machine):"
echo "   scp -i ~/.ssh/my-ec2-key.pem err-dataset-orig.csv ec2-user@\$INSTANCE_IP:/opt/data/err-dataset.csv"
echo ""
echo "4. Deploy the application:"
echo "   ./deploy-app.sh"
echo ""
echo "5. Monitor the application:"
echo "   ./monitor-logs.sh"
echo ""

echo -e "${GREEN}🎓 Week 2 SSH Deployment Lab Setup Complete!${NC}"