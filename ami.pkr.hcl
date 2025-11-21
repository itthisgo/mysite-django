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
      "echo '[1/5] Updating system packages...'",
      "sudo apt update -y && sudo apt install -y unzip curl nfs-common",

      "echo '[2/5] Installing AWS CLI v2...'",
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o '/tmp/awscliv2.zip'",
      "unzip /tmp/awscliv2.zip -d /tmp",
      "sudo /tmp/aws/install",

      "echo '[3/5] Preparing Django app directory...'",
      "sudo mkdir -p /home/ubuntu/django_work/mysite",
      "sudo chown -R ubuntu:ubuntu /home/ubuntu/django_work",

      "echo '[4/5] Downloading latest Django app zip from S3...'",
      "aws s3 cp s3://${var.s3_bucket}/mysite-deploy.zip /tmp/mysite-deploy.zip",
      "sudo unzip -o /tmp/mysite-deploy.zip -d /home/ubuntu/django_work/mysite",

      "echo '[5/5] Ensuring Gunicorn service enabled...'",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable gunicorn",
      "sudo rm -f /tmp/mysite-deploy.zip",
      "echo '[DONE] AMI build complete.'"
    ]
  }
}
