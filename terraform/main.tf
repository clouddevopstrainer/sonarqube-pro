provider "aws" {
  region = var.region
}

# Security group to allow SSH, HTTP, NodePort
resource "aws_security_group" "devnw_sg1" {
  name        = "dev-sgnw"
  description = "Allow SSH, HTTP, NodePort"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes NodePort"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-sgnw"
  }
}

# EC2 instance for app deployment
resource "aws_instance" "app_servernew" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devnw_sg1.id]   # ✅ fixed reference

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt upgrade -y

              # Install Docker
              apt install -y docker.io
              usermod -aG docker ubuntu

              # Start Docker
              systemctl start docker
              systemctl enable docker

              # Install Minikube
              curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
              install minikube-linux-amd64 /usr/local/bin/minikube

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
              EOF

  tags = {
    Name = "EC2-App-Servernew"
  }
}

# Output public IP
output "instance_public_ip" {
  value = aws_instance.app_servernew.public_ip
}
