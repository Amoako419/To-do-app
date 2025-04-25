variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "ami_id" {
  description = "AMI ID for Linux"
  type        = string
  default     = "ami-0df368112825f8d8f"  # Your specified Linux AMI
}