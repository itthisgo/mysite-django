#!/bin/bash
set -e

echo "Starting Gunicorn service..."

APP_DIR=/home/ubuntu/django_work/mysite
VENV_DIR=/home/ubuntu/venv

sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOF
[Unit]
Description=Gunicorn Daemon for Django App
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=$APP_DIR
ExecStart=$VENV_DIR/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 mysite.wsgi:application
EnvironmentFile=/etc/environment
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn

echo "✅ Gunicorn started successfully."
sudo systemctl status gunicorn --no-pager

