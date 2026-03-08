#!/bin/bash

PID_FILE="/tmp/cloudflared_tunnel.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        rm -f "$PID_FILE"
        echo "隧道已关闭 (PID: $PID)"
    else
        echo "进程不存在，清理 PID 文件"
        rm -f "$PID_FILE"
    fi
else
    # 兜底：直接 kill 所有 cloudflared 进程
    if pgrep cloudflared > /dev/null; then
        pkill cloudflared
        echo "隧道已关闭"
    else
        echo "没有运行中的隧道"
    fi
fi
