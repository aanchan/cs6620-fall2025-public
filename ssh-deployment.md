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

### 2. Create EC2 Key Pair
```bash
# Create EC2 Key Pair for instance access
aws ec2 create-key-pair --key-name my-ec2-key --query 'KeyMaterial' --output text > ~/.ssh/my-ec2-key.pem

# Set correct permissions
chmod 400 ~/.ssh/my-ec2-key.pem
```

### 3. Create Secure Security Group
```bash
# Get your current public IP address
MY_IP=$(curl -s https://checkip.amazonaws.com)/32

# Create security group with SSH access restricted to your IP only
aws ec2 create-security-group --group-name ssh-only --description "SSH access for deployment"

# Add SSH rule for your IP only (SECURE - recommended)
aws ec2 authorize-security-group-ingress --group-name ssh-only --protocol tcp --port 22 --cidr $MY_IP

# ⚠️  SECURITY WARNING: Never use 0.0.0.0/0 for SSH access in production!
# This would allow SSH access from anywhere on the internet:
# aws ec2 authorize-security-group-ingress --group-name ssh-only --protocol tcp --port 22 --cidr 0.0.0.0/0  # DON'T DO THIS!
```

### 4. Launch AWS EC2 Instance
```bash
# Launch EC2 instance with AWS CLI
# Get the latest Amazon Linux 2 AMI ID for your region
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*" --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text)

# Option 1: Using default security group (SSH will be BLOCKED - for demonstration)
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name my-ec2-key \
    --security-groups default

# Option 2: Using secure ssh-only group (SSH will work)
aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name my-ec2-key \
    --security-groups ssh-only
```

### 5. Connect to Server
```bash
# Get instance public IP
INSTANCE_IP=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Connecting to: $INSTANCE_IP"

# SSH into server using EC2 Key Pair
ssh -i ~/.ssh/my-ec2-key.pem ec2-user@$INSTANCE_IP

# If you get "Operation timed out" error, your instance likely uses the 'default' 
# security group which blocks SSH. Fix by modifying the security group:
# aws ec2 modify-instance-attribute --instance-id INSTANCE_ID --groups sg-xxxxx
```

---

## 🛠️ Server Setup (Automated)

### Run the Setup Script
```bash
# SSH into server
ssh -i ~/.ssh/my-ec2-key.pem ec2-user@$INSTANCE_IP

# Install git first
sudo yum install -y git

# Generate SSH key for GitHub access on the server
ssh-keygen -t ed25519 -C "ec2-user@$(hostname)" -f ~/.ssh/github_key -N ""

# Configure SSH to use the key for GitHub
cat >> ~/.ssh/config <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_key
EOF

# Set proper permissions for SSH files
chmod 600 ~/.ssh/config ~/.ssh/github_key
chmod 644 ~/.ssh/github_key.pub

# Display the public key to add to GitHub
echo "📋 Copy this public key and add it to your GitHub account:"
echo "   Go to: GitHub Settings > SSH and GPG keys > New SSH key"
echo ""
cat ~/.ssh/github_key.pub
echo ""
echo "⏸️  After adding the key to GitHub, press Enter to continue..."
read

# Test GitHub SSH connection
ssh -T git@github.com

# Clone the repository using SSH (includes server-setup.sh)
git clone git@github.com:aanchan/cs6620-educational-repo.git
cd cs6620-educational-repo

# Checkout the week-02 branch
git checkout week-02-basic-app

# Run the setup script
chmod +x server-setup.sh
./server-setup.sh
```

The setup script will automatically:
- ✅ Update system packages
- ✅ Install Python, pip, git, nginx
- ✅ Create application directories
- ✅ Configure nginx as reverse proxy
- ✅ Create systemd service file
- ✅ Generate helper scripts for deployment and monitoring

---

## 🔍 Understanding the Setup (Manual Commands)

*This section shows what the `server-setup.sh` script does under the hood for learning purposes:*

### Manual Server Configuration Steps
```bash
#!/bin/bash
# These are the individual commands that server-setup.sh runs automatically

echo "🔧 Setting up server for Speech Labeling Interface"

# Update system packages
sudo yum update -y

# Install required packages
sudo yum install -y python3 python3-pip git nginx curl wget

# Install Python dependencies
pip3 install --user flask flask-cors pydub

# Create application directory
sudo mkdir -p /opt/speech-labeling
sudo chown ec2-user:ec2-user /opt/speech-labeling

# Create data directories
sudo mkdir -p /opt/audio /opt/data
sudo chown ec2-user:ec2-user /opt/audio /opt/data

# Configure nginx (this is done automatically by the script)
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

echo "✅ Server setup complete!"
```

---

## 📦 Manual Deployment Process

### 1. Upload Application Files
```bash
# From your local machine, upload files to server
scp -i ~/.ssh/my-ec2-key.pem -r . ec2-user@$INSTANCE_IP:/opt/speech-labeling/

# Alternative: Clone from Git repository
ssh -i ~/.ssh/my-ec2-key.pem ec2-user@$INSTANCE_IP
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
ssh -i ~/.ssh/my-ec2-key.pem ec2-user@\$SERVER_IP "mkdir -p /opt/audio"

# Upload files with progress
rsync -avz --progress -e "ssh -i ~/.ssh/my-ec2-key.pem" \
    \$AUDIO_DIR/ ec2-user@\$SERVER_IP:/opt/audio/

echo "✅ Audio files uploaded successfully!"
EOF

chmod +x upload-audio.sh
```

### CSV Data Upload
```bash
# Upload CSV data file
scp -i ~/.ssh/my-ec2-key.pem err-dataset-orig.csv ec2-user@$INSTANCE_IP:/opt/data/err-dataset.csv

# Set permissions
ssh -i ~/.ssh/my-ec2-key.pem ec2-user@$INSTANCE_IP "chmod 644 /opt/data/err-dataset.csv"
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

# 2. Create EC2 Key Pair
aws ec2 create-key-pair --key-name my-ec2-key --query 'KeyMaterial' --output text > ~/.ssh/my-ec2-key.pem
chmod 400 ~/.ssh/my-ec2-key.pem

# 3. Create secure security group
MY_IP=$(curl -s https://checkip.amazonaws.com)/32
aws ec2 create-security-group --group-name ssh-only --description "SSH access for deployment"
aws ec2 authorize-security-group-ingress --group-name ssh-only --protocol tcp --port 22 --cidr $MY_IP

# 4. Launch EC2 instance
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*" --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text)
aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro --key-name my-ec2-key --security-groups ssh-only

# 4. Connect and set up server
ssh -i ~/.ssh/my-ec2-key.pem ec2-user@$INSTANCE_IP
./server-setup.sh

# 5. Deploy application manually
scp -i ~/.ssh/my-ec2-key.pem -r . ec2-user@$INSTANCE_IP:/opt/speech-labeling/

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