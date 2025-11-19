#!/bin/bash
set -e

echo "[BeforeInstall] Checking and preparing directories..."

# 프로젝트 루트 경로
BASE_DIR="/home/ubuntu/django_work"
APP_DIR="$BASE_DIR/mysite"

# 폴더 존재 확인 및 생성
if [ ! -d "$BASE_DIR" ]; then
  echo "- Creating base directory: $BASE_DIR"
  sudo mkdir -p "$BASE_DIR"
  sudo chown ubuntu:ubuntu "$BASE_DIR"
fi

if [ ! -d "$APP_DIR" ]; then
  echo "- Creating app directory: $APP_DIR"
  sudo mkdir -p "$APP_DIR"
  sudo chown -R ubuntu:ubuntu "$APP_DIR"
fi

# 로그 디렉토리도 함께 보정
LOG_FILE="$APP_DIR/django.log"
if [ ! -f "$LOG_FILE" ]; then
  echo "- Creating log file: $LOG_FILE"
  sudo touch "$LOG_FILE"
fi

sudo chown -R ubuntu:ubuntu $APP_DIR
sudo chmod -R 755 $APP_DIR

echo "[BeforeInstall] Directory preparation complete."
