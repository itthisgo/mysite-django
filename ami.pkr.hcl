packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "source_ami" {
  type    = string
  default = "ami-0662f4965dfc70aca"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "s3_bucket" {
  type = string
}

variable "efs_id" {
  type = string
  default = "fs-04a0b7c472807a55d"
}

source "amazon-ebs" "mysite_ami" {
  region                      = var.aws_region
  source_ami                  = var.source_ami
  instance_type               = var.instance_type
  ssh_username                = "ubuntu"
  ami_name                    = "mysite-django-{{timestamp}}"
  associate_public_ip_address = true
  vpc_id                      = "vpc-062f26948615555c4"
  subnet_id                   = "subnet-06d864708de5e6457"
  iam_instance_profile        = "mysite-s3-fullaccess"

  tags = {
    Name = "mysite-django-ami"
  }
}

build {
  sources = ["source.amazon-ebs.mysite_ami"]

  provisioner "shell" {
    inline = [
      "echo '[1/8] Updating apt packages...'",
      "sudo apt update -y",
      "sudo apt install -y python3 python3-venv python3-pip nginx curl unzip nfs-common",

      "echo '[2/8] Installing AWS CLI v2...'",
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o '/tmp/awscliv2.zip'",
      "unzip /tmp/awscliv2.zip -d /tmp",
      "sudo /tmp/aws/install",

      "echo '[3/8] Setting up Django app directory...'",
      "sudo mkdir -p /home/ubuntu/django_work/mysite",
      "sudo aws s3 cp s3://${var.s3_bucket}/mysite-deploy.zip /home/ubuntu/mysite-deploy.zip",
      "cd /home/ubuntu/django_work/mysite && sudo unzip /home/ubuntu/mysite-deploy.zip -d .",

      "echo '[4/8] Setting up Python venv & dependencies...'",
      "python3 -m venv /home/ubuntu/venv",
      "bash -c 'source /home/ubuntu/venv/bin/activate && pip install --upgrade pip && pip install django gunicorn mysqlclient'",

      "echo '[5/8] Creating Gunicorn systemd service file...'",
      "sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOF",
      "[Unit]",
      "Description=Gunicorn Daemon for Django",
      "After=network.target",
      "",
      "[Service]",
      "User=ubuntu",
      "Group=ubuntu",
      "WorkingDirectory=/home/ubuntu/django_work/mysite",
      "Environment=\"PATH=/home/ubuntu/venv/bin\"",
      "ExecStart=/home/ubuntu/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 mysite.wsgi:application",
      "EnvironmentFile=/etc/environment",
      "Restart=always",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",

      "echo '[6/8] Creating EFS mount systemd service...'",
      "sudo tee /etc/systemd/system/mount-efs.service > /dev/null <<EOF",
      "[Unit]",
      "Description=Mount EFS on startup",
      "After=network-online.target",
      "Wants=network-online.target",
      "",
      "[Service]",
      "Type=oneshot",
      "ExecStart=/usr/bin/bash -c \"mkdir -p /mnt/efs /home/ubuntu/django_work/mysite/media && mount -t nfs4 -o nfsvers=4.1 ${var.efs_id}.efs.ap-northeast-2.amazonaws.com:/ /mnt/efs && mount --bind /mnt/efs /home/ubuntu/django_work/mysite/media && chown -R ubuntu:ubuntu /home/ubuntu/django_work/mysite/media\"",
      "RemainAfterExit=yes",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",

      "echo '[7/8] Enabling services...'",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable gunicorn",
      "sudo systemctl enable mount-efs",

      "echo '[8/8] Build process complete!!'"
    ]
  }
}
