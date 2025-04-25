provider "aws" {
  region = var.aws_region
}

# Use existing DynamoDB table
data "aws_dynamodb_table" "terraform_state_lock" {
  name = "terraform-state-lock"
}

# Data source for existing S3 bucket
data "aws_s3_bucket" "terraform_state" {
  bucket = "todo-app-terraform-state"
}

# VPC Configuration
resource "aws_vpc" "todo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "todo-app-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.todo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "todo-app-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "todo_igw" {
  vpc_id = aws_vpc.todo_vpc.id

  tags = {
    Name = "todo-app-igw"
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.todo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.todo_igw.id
  }

  tags = {
    Name = "todo-app-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "todo_sg" {
  name        = "todo-app-sg"
  description = "Security group for Todo app"
  vpc_id      = aws_vpc.todo_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "todo-app-sg"
  }
}

# EC2 Instance
resource "aws_instance" "todo_app" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id

  vpc_security_group_ids = [aws_security_group.todo_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y python3-pip nginx git
              sudo systemctl start nginx
              sudo systemctl enable nginx

              # Clone the application
              git clone https://github.com/yourusername/todo-app.git /home/ubuntu/todo-app

              # Install dependencies
              cd /home/ubuntu/todo-app
              pip3 install -r requirements.txt

              # Setup systemd service
              cat << 'EOT' > /etc/systemd/system/todo-app.service
              [Unit]
              Description=Todo App
              After=network.target

              [Service]
              User=ubuntu
              WorkingDirectory=/home/ubuntu/todo-app
              ExecStart=/usr/bin/python3 app/app.py
              Restart=always

              [Install]
              WantedBy=multi-user.target
              EOT

              # Start the service
              sudo systemctl start todo-app
              sudo systemctl enable todo-app

              # Configure Nginx
              cat << 'EOT' > /etc/nginx/sites-available/todo-app
              server {
                  listen 80;
                  server_name _;

                  location / {
                      proxy_pass http://127.0.0.1:5000;
                      proxy_set_header Host $host;
                      proxy_set_header X-Real-IP $remote_addr;
                  }
              }
              EOT

              sudo ln -s /etc/nginx/sites-available/todo-app /etc/nginx/sites-enabled/
              sudo rm /etc/nginx/sites-enabled/default
              sudo systemctl restart nginx
              EOF

  tags = {
    Name = "todo-app-instance"
  }
}

# Elastic IP
resource "aws_eip" "todo_app_eip" {
  instance = aws_instance.todo_app.id
  domain   = "vpc"

  tags = {
    Name = "todo-app-eip"
  }
}