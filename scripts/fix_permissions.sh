#!/bin/bash
set -e

APP_DIR="/home/ubuntu/django_work/mysite"
LOG_FILE="$APP_DIR/django.log"

echo "[BeforeAllowTraffic] Fixing ownership and permissions..."

# 프로젝트 전체 소유자 ubuntu로
sudo chown -R ubuntu:ubuntu $APP_DIR
sudo chmod -R 755 $APP_DIR

# 로그 파일 없으면 생성
if [ ! -f "$LOG_FILE" ]; then
  sudo touch "$LOG_FILE"
fi

sudo chown ubuntu:ubuntu "$LOG_FILE"
sudo chmod 664 "$LOG_FILE"

echo "[BeforeAllowTraffic] Permission fix completed."

