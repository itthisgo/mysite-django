#!/bin/bash
set -e

EFS_ID=${EFS_ID}
EFS_DIR="/mnt/efs"
MEDIA_DIR="/home/ubuntu/django_work/mysite/media"

echo "[Mount] Using EFS ID: $EFS_ID"

# NFS 패키지 확인
if ! dpkg -l | grep -q nfs-common; then
  echo "[Mount] Installing nfs-common..."
  sudo apt update -y && sudo apt install -y nfs-common
fi

# 기존 마운트 있으면 해제 (재배포 시 덮어쓰기 방지)
if mountpoint -q "$MEDIA_DIR"; then
  echo "[Mount] Unmounting old EFS from $MEDIA_DIR..."
  sudo umount "$MEDIA_DIR" || true
fi
if mountpoint -q "$EFS_DIR"; then
  echo "[Mount] Unmounting old EFS from $EFS_DIR..."
  sudo umount "$EFS_DIR" || true
fi

# 마운트 경로 보장
sudo mkdir -p "$EFS_DIR" "$MEDIA_DIR"

# EFS 마운트
sudo mount -t nfs4 -o nfsvers=4.1 ${EFS_ID}.efs.ap-northeast-2.amazonaws.com:/ "$EFS_DIR"
sudo mount --bind "$EFS_DIR" "$MEDIA_DIR"

# 권한 조정
sudo chown -R ubuntu:ubuntu "$MEDIA_DIR"
sudo chmod -R 755 "$MEDIA_DIR"

echo "[Mount] EFS successfully mounted to $MEDIA_DIR"

