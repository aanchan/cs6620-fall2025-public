#!/bin/bash
# start.sh - Start the speech labeling application

echo "🚀 Starting Speech Labeling Application..."

# Check if gunicorn is already running
if pgrep -f "gunicorn.*app:app" > /dev/null; then
    echo "⚠️  Application is already running!"
    echo "Run ./stop.sh first to stop it, or check with: ps aux | grep gunicorn"
    exit 1
fi

# Install dependencies if requirements.txt exists
if [ -f requirements.txt ]; then
    echo "🐍 Installing Python dependencies..."
    pip3 install --user -r requirements.txt
fi

# Start gunicorn in daemon mode
echo "⚙️  Starting gunicorn server..."
sudo PYTHONPATH="/home/ec2-user/.local/lib/python3.9/site-packages:$PYTHONPATH" /home/ec2-user/.local/bin/gunicorn -w 4 -b 0.0.0.0:80 --daemon app:app

# Check if it started successfully
sleep 2
if pgrep -f "gunicorn.*app:app" > /dev/null; then
    echo "✅ Application started successfully!"
    echo "🔍 Access your application at: http://$(curl -s ifconfig.me)"
    echo "🎛️  Labeling interface: http://$(curl -s ifconfig.me)/labeling"
    echo ""
    echo "💡 To stop the application, run: ./stop.sh"
    echo "💡 To check status, run: ps aux | grep gunicorn"
else
    echo "❌ Failed to start application!"
    echo "Check the logs or try running without daemon mode for debugging:"
    echo "sudo PYTHONPATH=\"/home/ec2-user/.local/lib/python3.9/site-packages:\$PYTHONPATH\" /home/ec2-user/.local/bin/gunicorn -w 4 -b 0.0.0.0:80 app:app"
    exit 1
fi