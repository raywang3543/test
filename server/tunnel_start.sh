#!/bin/bash

LOG_FILE="/tmp/cloudflared_tunnel.log"
PID_FILE="/tmp/cloudflared_tunnel.pid"

if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "隧道已在运行中 (PID: $(cat $PID_FILE))"
    exit 1
fi

echo "正在启动 Cloudflare Tunnel (localhost:8000)..."
nohup cloudflared tunnel --url http://localhost:8000 > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

echo "等待隧道建立..."
for i in $(seq 1 15); do
    URL=$(grep -o 'https://[a-zA-Z0-9.-]*\.trycloudflare\.com' "$LOG_FILE" 2>/dev/null | head -1)
    if [ -n "$URL" ]; then
        echo "隧道启动成功！"
        echo "公网地址: $URL"
        exit 0
    fi
    sleep 1
done

echo "隧道启动超时，请查看日志: $LOG_FILE"
exit 1
