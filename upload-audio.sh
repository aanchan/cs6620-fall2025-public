#!/bin/bash

# upload-audio.sh - Upload audio files to server
# Week 2: SSH Deployment Lab

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SERVER_IP=$1
AUDIO_DIR=$2
SSH_KEY=${3:-~/.ssh/id_ed25519}

if [ -z "$SERVER_IP" ] || [ -z "$AUDIO_DIR" ]; then
    echo -e "${RED}❌ Usage: $0 <server-ip> <local-audio-directory> [ssh-key-path]${NC}"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 54.123.45.67 ./audio-files"
    echo "  $0 54.123.45.67 /Users/student/wav ~/.ssh/my_key"
    exit 1
fi

if [ ! -d "$AUDIO_DIR" ]; then
    echo -e "${RED}❌ Audio directory not found: $AUDIO_DIR${NC}"
    exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}❌ SSH key not found: $SSH_KEY${NC}"
    exit 1
fi

echo -e "${GREEN}🎵 Uploading audio files to Speech Labeling Server${NC}"
echo -e "${BLUE}📁 Local directory: $AUDIO_DIR${NC}"
echo -e "${BLUE}🌐 Server: $SERVER_IP${NC}"
echo -e "${BLUE}🔑 SSH key: $SSH_KEY${NC}"

# Test SSH connection
echo -e "${YELLOW}🔍 Testing SSH connection...${NC}"
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$SERVER_IP "echo 'Connection successful'" > /dev/null; then
    echo -e "${RED}❌ SSH connection failed. Check your server IP and SSH key.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SSH connection successful${NC}"

# Create remote directory
echo -e "${YELLOW}📁 Creating remote audio directory...${NC}"
ssh -i "$SSH_KEY" ec2-user@$SERVER_IP "mkdir -p /opt/audio"

# Count files to upload
FILE_COUNT=$(find "$AUDIO_DIR" -type f \( -name "*.wav" -o -name "*.mp3" -o -name "*.ogg" \) | wc -l)
echo -e "${BLUE}📊 Found $FILE_COUNT audio files to upload${NC}"

if [ $FILE_COUNT -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No audio files found in $AUDIO_DIR${NC}"
    echo "Looking for files with extensions: .wav, .mp3, .ogg"
    exit 1
fi

# Upload files with progress
echo -e "${YELLOW}📤 Uploading audio files...${NC}"
rsync -avz --progress \
    --include="*.wav" --include="*.mp3" --include="*.ogg" \
    --include="*/" --exclude="*" \
    -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" \
    "$AUDIO_DIR/" ec2-user@$SERVER_IP:/opt/audio/

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Audio files uploaded successfully!${NC}"
    
    # Show uploaded files
    echo -e "${YELLOW}📋 Verifying upload...${NC}"
    UPLOADED_COUNT=$(ssh -i "$SSH_KEY" ec2-user@$SERVER_IP "find /opt/audio -type f \( -name '*.wav' -o -name '*.mp3' -o -name '*.ogg' \) | wc -l")
    echo -e "${GREEN}📊 $UPLOADED_COUNT files uploaded to server${NC}"
    
    # Set proper permissions
    echo -e "${YELLOW}🔒 Setting file permissions...${NC}"
    ssh -i "$SSH_KEY" ec2-user@$SERVER_IP "chmod -R 644 /opt/audio/*.{wav,mp3,ogg} 2>/dev/null || true"
    ssh -i "$SSH_KEY" ec2-user@$SERVER_IP "chmod 755 /opt/audio"
    
    echo ""
    echo -e "${GREEN}🎉 Upload complete!${NC}"
    echo ""
    echo -e "${YELLOW}📝 Next steps:${NC}"
    echo "1. Upload your CSV data file:"
    echo "   scp -i $SSH_KEY err-dataset.csv ec2-user@$SERVER_IP:/opt/data/"
    echo ""
    echo "2. Deploy your application:"
    echo "   ssh -i $SSH_KEY ec2-user@$SERVER_IP './deploy-app.sh'"
    echo ""
    echo "3. Access your application:"
    echo "   http://$SERVER_IP/labeling"
    
else
    echo -e "${RED}❌ Upload failed!${NC}"
    exit 1
fi