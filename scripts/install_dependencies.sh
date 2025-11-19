#!/bin/bash
set -e  # 오류 시 즉시 중단

APP_DIR="/home/ubuntu/django_work/mysite"
VENV_DIR="/home/ubuntu/venv"

echo "[1/3] Creating virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv $VENV_DIR
fi

echo "[2/3] Activating virtual environment..."
source $VENV_DIR/bin/activate

echo "[3/3] Installing Python dependencies..."
pip install --upgrade pip
pip install django gunicorn mysqlclient

