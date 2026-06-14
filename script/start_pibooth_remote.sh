#!/bin/bash
cd /home/lucas/Rasb_booth/pibooth
source venv/bin/activate
export DISPLAY=:0

pkill -f "python.*pibooth" 2>/dev/null
sleep 1

pibooth --verbose > /tmp/pb.log 2>&1 &
PB_PID=$!
echo "Pibooth started with PID=$PB_PID"

sleep 10

echo "=== Log output ==="
cat /tmp/pb.log
echo "=== Process check ==="
ps aux | grep pibooth | grep -v grep
echo "=== Port 3000 ==="
ss -tlnp | grep 3000