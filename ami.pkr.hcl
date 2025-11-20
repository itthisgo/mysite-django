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
  default = "t3.micro"
}

variable "s3_bucket" {
  type = string
}

source "amazon-ebs" "mysite_ami" {
  region                      = var.aws_region
  source_ami                  = var.source_ami
  instance_type               = var.instance_type
  ssh_username                = "ubuntu"
  ami_name                    = "mysite-django-{{timestamp}}"
  associate_public_ip_address = true
  iam_instance_profile        = "mysiteRole"

  tags = {
    Name = "mysite-django-ami"
  }
}

build {
  sources = ["source.amazon-ebs.mysite_ami"]

  provisioner "shell" {
    inline = [
      "echo '[1/7] Updating system packages...'",
      "sudo apt update -y && sudo apt install -y python3-pip python3-venv unzip curl nfs-common awscli",

      "echo '[2/7] Setting up Django project directory...'",
      "sudo mkdir -p /home/ubuntu/django_work/mysite",
      "sudo chown -R ubuntu:ubuntu /home/ubuntu/django_work",

      "echo '[3/7] Downloading latest app zip from S3...'",
      "aws s3 cp s3://${var.s3_bucket}/mysite-deploy.zip /tmp/mysite-deploy.zip",
      "sudo unzip -o /tmp/mysite-deploy.zip -d /home/ubuntu/django_work/mysite",

      "echo '[4/7] Setting up virtual environment...'",
      "cd /home/ubuntu/django_work/mysite && python3 -m venv /home/ubuntu/venv",
      "source /home/ubuntu/venv/bin/activate && pip install --upgrade pip",
      "source /home/ubuntu/venv/bin/activate && pip install -r requirements.txt",
      "deactivate",

      "echo '[5/7] Ensuring /etc/environment remains intact (no overwrite)...'",
      "if [ ! -f /etc/environment ]; then echo 'ERROR: /etc/environment missing, aborting'; exit 1; fi",

      "echo '[6/7] Creating Gunicorn service...'",
      <<-EOF
sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOL
[Unit]
Description=Gunicorn Daemon for Django App
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/django_work/mysite
EnvironmentFile=/etc/environment
ExecStart=/home/ubuntu/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 mysite.wsgi:application
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL
EOF
      ,
      "echo '[7/7] Enabling Gunicorn service...'",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable gunicorn",
      "sudo rm -f /tmp/mysite-deploy.zip",
      "echo '[DONE] AMI build complete.'"
    ]
  }
}
