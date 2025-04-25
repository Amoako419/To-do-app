variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS"
  type        = string
  default     = "ami-0735c191cf914754d"  # Ubuntu 22.04 LTS in us-west-2
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}