variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "ami_id" {
  description = "AMI ID for Linux"
  type        = string
  default     = "ami-0ce8c2b29fcc8a346"  # Your specified Linux AMI
}