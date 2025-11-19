#!/bin/bash
echo "Stopping Gunicorn..."
sudo systemctl stop gunicorn || true

