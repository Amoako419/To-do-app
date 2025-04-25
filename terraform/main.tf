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

  user_data = <<EOF
#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1

# Update system and install dependencies
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip nginx git

# Create application directory
mkdir -p /opt/todo-app
cd /opt/todo-app

# Clone the application
git clone https://github.com/Amoako419/To-do-app.git .

# Install Python dependencies
python3 -m pip install -r requirements.txt

# Create Flask service file
cat > /etc/systemd/system/todo-app.service << "EOL"
[Unit]
Description=Todo App Flask Service
After=network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/todo-app
Environment="PATH=/usr/local/bin"
ExecStart=/usr/local/bin/python3 app/app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL

# Configure Nginx
cat > /etc/nginx/sites-available/todo-app << "EOL"
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/todo-app.access.log;
    error_log /var/log/nginx/todo-app.error.log;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Enable and configure services
ln -sf /etc/nginx/sites-available/todo-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Set permissions
chown -R ubuntu:ubuntu /opt/todo-app
chmod -R 755 /opt/todo-app

# Create and set permissions for log file
touch /var/log/todo-app.log
chown ubuntu:ubuntu /var/log/todo-app.log

# Start services
systemctl daemon-reload
systemctl enable todo-app
systemctl start todo-app
systemctl restart nginx
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