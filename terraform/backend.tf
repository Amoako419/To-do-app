terraform {
  backend "s3" {
    bucket         = "todo-app-terraform-state"
    key            = "todo-app/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}