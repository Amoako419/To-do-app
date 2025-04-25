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

    ingress {
        from_port   = 22
        to_port     = 22
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
# Redirect all outputs to user-data.log for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting user data script execution"

# Wait for cloud-init to complete
cloud-init status --wait

# Update package list
echo "Updating package list"
apt-get update -y

# Install required packages
echo "Installing required packages"
DEBIAN_FRONTEND=noninteractive apt-get install -y \\
    python3-pip \\
    python3-venv \\
    nginx \\
    git

# Create application directory
echo "Setting up application directory"
APP_DIR=/opt/todo-app
mkdir -p $APP_DIR
cd $APP_DIR

# Clone the application
echo "Cloning application repository"
git clone https://github.com/Amoako419/To-do-app.git .

# Setup Python virtual environment
echo "Setting up Python virtual environment"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Create systemd service file
echo "Creating systemd service"
cat > /etc/systemd/system/todo-app.service << 'EOT'
[Unit]
Description=Todo App Flask Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/todo-app
Environment="PATH=/opt/todo-app/venv/bin"
ExecStart=/opt/todo-app/venv/bin/python3 app/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOT

# Configure Nginx
echo "Configuring Nginx"
cat > /etc/nginx/sites-available/todo-app << 'EOT'
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/todo-app.access.log;
    error_log /var/log/nginx/todo-app.error.log;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOT

# Set proper permissions
echo "Setting file permissions"
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

# Enable and configure services
echo "Configuring services"
ln -sf /etc/nginx/sites-available/todo-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Start and enable services
echo "Starting services"
systemctl daemon-reload
systemctl enable todo-app
systemctl start todo-app
systemctl restart nginx

echo "User data script completed"
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