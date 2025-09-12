#!/bin/bash
# stop.sh - Stop the speech labeling application

echo "🛑 Stopping Speech Labeling Application..."

# Find and kill gunicorn processes
PIDS=$(pgrep -f "gunicorn.*app:app")

if [ -z "$PIDS" ]; then
    echo "ℹ️  No running application found."
    exit 0
fi

echo "🔍 Found running processes: $PIDS"

# Kill the processes
for PID in $PIDS; do
    echo "Stopping process $PID..."
    sudo kill $PID
done

# Wait a moment and check if they're really stopped
sleep 2

if pgrep -f "gunicorn.*app:app" > /dev/null; then
    echo "⚠️  Some processes are still running, force killing..."
    sudo pkill -f "gunicorn.*app:app"
    sleep 1
fi

# Final check
if pgrep -f "gunicorn.*app:app" > /dev/null; then
    echo "❌ Failed to stop all processes. Try manually:"
    echo "sudo pkill -9 -f 'gunicorn.*app:app'"
    exit 1
else
    echo "✅ Application stopped successfully!"
fi