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
        "echo '[1/5] Updating apt packages...'",
        "sudo apt update -y",
        "sudo apt install -y python3 python3-venv python3-pip nginx",

        "echo '[2/5] Setting up Django app directory...'",
        "sudo mkdir -p /home/ubuntu/django_work/mysite",
        "sudo aws s3 cp s3://${var.s3_bucket}/mysite-deploy.zip /home/ubuntu/mysite-deploy.zip",
        "cd /home/ubuntu/django_work/mysite && sudo unzip /home/ubuntu/mysite-deploy.zip -d .",

        "echo '[3/5] Setting up virtualenv and installing packages...'",
        "python3 -m venv /home/ubuntu/venv",
        "source /home/ubuntu/venv/bin/activate && pip install --upgrade pip && pip install django gunicorn mysqlclient",

        "echo '[4/5] Creating Gunicorn systemd service file...'",
        "sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOF",
        "[Unit]",
        "Description=Gunicorn Daemon for Django",
        "After=network.target",
        "",
        "[Service]",
        "User=ubuntu",
        "Group=ubuntu",
        "WorkingDirectory=/home/ubuntu/django_work/mysite",
        "ExecStart=/home/ubuntu/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 mysite.wsgi:application",
        "EnvironmentFile=/etc/environment",
        "Restart=always",
        "",
        "[Install]",
        "WantedBy=multi-user.target",
        "EOF",

        "echo '[5/5] Enabling and starting Gunicorn service...'",
        "sudo systemctl daemon-reload",
        "sudo systemctl enable gunicorn",
        "sudo systemctl start gunicorn"
    ]
  }
}
