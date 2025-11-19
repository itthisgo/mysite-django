# scripts/cleanup_old_deploy.sh
#!/bin/bash
DEPLOY_DIR="/home/ubuntu/django_work/mysite"

echo "[Cleanup] Checking EFS mount..."
MEDIA_DIR="$DEPLOY_DIR/media"
if mountpoint -q "$MEDIA_DIR"; then
  echo "[Cleanup] $MEDIA_DIR is mounted. Unmounting first..."
  sudo umount "$MEDIA_DIR"
fi

if [ -d "$DEPLOY_DIR" ]; then
  echo "[Cleanup] Removing old local media directory..."
  find "$DEPLOY_DIR" -maxdepth 1 -type d -not -name "media" -not -name "." -exec rm -rf {} +
  find "$DEPLOY_DIR" -maxdepth 1 -type f -name "*.tmp" -delete
else
  echo "[Cleanup] $DEPLOY_DIR not found. Skipping directory cleanup."
fi

echo "[Cleanup] Complete."

