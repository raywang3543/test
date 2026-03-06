#!/bin/zsh
pids=$(lsof -ti :8000)
if [ -z "$pids" ]; then
  echo "服务器未运行"
else
  echo "$pids" | xargs kill
  echo "服务器已停止"
fi
