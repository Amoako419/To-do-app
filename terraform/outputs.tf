output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.todo_app_eip.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.todo_app.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.todo_vpc.id
}