# Week 2: SSH Deployment - Basic Server Setup

## 🚀 CS6620 Week 2: SSH Deployment Lab

Learn to deploy your speech labeling application using SSH and basic server administration.

---

## 🎯 Learning Objectives

- Understand SSH key authentication
- Learn basic Linux server administration
- Deploy Flask applications manually
- Configure system services (systemd)
- Understand file permissions and user management

---

## 🔑 SSH Key Setup

### 1. Generate SSH Keys (Local Machine)
```bash
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com"

# Start ssh-agent
eval "$(ssh-agent -s)"

# Add key to ssh-agent
ssh-add ~/.ssh/id_ed25519

# Display public key to copy
cat ~/.ssh/id_ed25519.pub
```

### 2. Launch AWS EC2 Instance
```bash
# Launch EC2 instance with AWS CLI
aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --count 1 \
    --instance-type t2.micro \
    --key-name your-key-name \
    --security-groups default \
    --user-data file://user-data.sh
```

### 3. Connect to Server
```bash
# Get instance public IP
INSTANCE_IP=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Connecting to: $INSTANCE_IP"

# SSH into server
ssh -i ~/.ssh/id_ed25519 ec2-user@$INSTANCE_IP
```

---

## 🛠️ Server Setup Script

### Initial Server Configuration
```bash
#!/bin/bash
# server-setup.sh - Initial server configuration

echo "🔧 Setting up server for Speech Labeling Interface"

# Update system packages
sudo yum update -y

# Install required packages
sudo yum install -y python3 python3-pip git nginx

# Install Python dependencies
pip3 install --user flask flask-cors pydub

# Create application directory
sudo mkdir -p /opt/speech-labeling
sudo chown ec2-user:ec2-user /opt/speech-labeling

# Create data directories
sudo mkdir -p /opt/audio /opt/data
sudo chown ec2-user:ec2-user /opt/audio /opt/data

echo "✅ Server setup complete!"
echo "📁 Application directory: /opt/speech-labeling"
echo "🎵 Audio directory: /opt/audio"
echo "📊 Data directory: /opt/data"
```

---

## 📦 Manual Deployment Process

### 1. Upload Application Files
```bash
# From your local machine, upload files to server
scp -i ~/.ssh/id_ed25519 -r . ec2-user@$INSTANCE_IP:/opt/speech-labeling/

# Alternative: Clone from Git repository
ssh -i ~/.ssh/id_ed25519 ec2-user@$INSTANCE_IP
cd /opt/speech-labeling
git clone https://github.com/yourusername/network-audio-player.git .
```

### 2. Install Python Dependencies
```bash
# On the server
cd /opt/speech-labeling

# Install requirements
pip3 install --user -r requirements.txt

# Test the application
python3 app.py
```

### 3. Configure as System Service
```bash
# Create systemd service file
sudo tee /etc/systemd/system/speech-labeling.service > /dev/null <<EOF
[Unit]
Description=Speech Error Labeling Interface
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/speech-labeling
Environment=PATH=/home/ec2-user/.local/bin
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable speech-labeling
sudo systemctl start speech-labeling

# Check service status
sudo systemctl status speech-labeling
```

---

## 🌐 Basic Web Server Configuration

### Nginx Configuration
```bash
# Create nginx configuration
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
    }
}
EOF

# Test nginx configuration
sudo nginx -t

# Start nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

---

## 🎵 Audio File Management

### Upload Audio Files
```bash
# Create audio upload script
cat > upload-audio.sh <<EOF
#!/bin/bash
# upload-audio.sh - Upload audio files to server

SERVER_IP=\$1
AUDIO_DIR=\$2

if [ -z "\$SERVER_IP" ] || [ -z "\$AUDIO_DIR" ]; then
    echo "Usage: \$0 <server-ip> <local-audio-directory>"
    exit 1
fi

echo "📁 Uploading audio files from \$AUDIO_DIR to \$SERVER_IP"

# Create remote directory
ssh -i ~/.ssh/id_ed25519 ec2-user@\$SERVER_IP "mkdir -p /opt/audio"

# Upload files with progress
rsync -avz --progress -e "ssh -i ~/.ssh/id_ed25519" \
    \$AUDIO_DIR/ ec2-user@\$SERVER_IP:/opt/audio/

echo "✅ Audio files uploaded successfully!"
EOF

chmod +x upload-audio.sh
```

### CSV Data Upload
```bash
# Upload CSV data file
scp -i ~/.ssh/id_ed25519 err-dataset-orig.csv ec2-user@$INSTANCE_IP:/opt/data/err-dataset.csv

# Set permissions
ssh -i ~/.ssh/id_ed25519 ec2-user@$INSTANCE_IP "chmod 644 /opt/data/err-dataset.csv"
```

---

## 🔧 Troubleshooting Common Issues

### Check Application Logs
```bash
# View application logs
sudo journalctl -u speech-labeling -f

# Check nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### File Permissions
```bash
# Fix ownership issues
sudo chown -R ec2-user:ec2-user /opt/speech-labeling
sudo chown -R ec2-user:ec2-user /opt/audio
sudo chown -R ec2-user:ec2-user /opt/data

# Fix execute permissions
chmod +x /opt/speech-labeling/app.py
```

### Network Issues
```bash
# Check if application is running
curl http://localhost:3000

# Check nginx proxy
curl http://localhost:80

# Test from outside
curl http://$INSTANCE_IP
```

---

## 📝 Lab Exercise - Week 2

### Complete SSH Deployment
```bash
# 1. Set up SSH keys
ssh-keygen -t ed25519 -C "student@cs6620.edu"

# 2. Launch EC2 instance
aws ec2 run-instances --image-id ami-0c02fb55956c7d316 --count 1 --instance-type t2.micro

# 3. Connect and set up server
./server-setup.sh

# 4. Deploy application manually
scp -r . ec2-user@$INSTANCE_IP:/opt/speech-labeling/

# 5. Configure as service
# (Follow systemd service setup above)

# 6. Configure web server
# (Follow nginx setup above)

# 7. Test deployment
curl http://$INSTANCE_IP/labeling
```

---

## 🎓 Key Concepts - Week 2

### SSH Authentication
- **Public/private key pairs**: More secure than passwords
- **ssh-agent**: Manages keys in memory
- **authorized_keys**: Server-side key storage

### Linux System Administration
- **systemd services**: Background process management
- **nginx**: Reverse proxy and web server
- **File permissions**: User, group, and other permissions
- **Process management**: Starting, stopping, monitoring services

### Manual Deployment
- **Direct file transfer**: SCP, RSYNC for file uploads
- **Service configuration**: Creating and managing system services
- **Web server setup**: Proxy configuration for Flask apps

---

## 💡 Best Practices

1. **Security**: Use SSH keys, not passwords
2. **Monitoring**: Set up log monitoring and service health checks  
3. **Backups**: Regular backups of application data and configurations
4. **Updates**: Keep system packages updated
5. **Resource monitoring**: Monitor CPU, memory, disk usage

---

## 🔄 Next Steps (Week 3)

After completing Week 2, students will learn:
- DNS configuration and domain setup
- SSL/TLS certificates and HTTPS
- Security groups and firewall configuration
- Static IP addresses with Elastic IPs

This manual deployment foundation prepares students for more advanced automation in later weeks!