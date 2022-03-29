variable "aws_credentials_file" {
  type = string
  description = "The file that contains the AWS credentials we will use."
  default = "~/.aws/credentials"
}

variable "aws_profile" {
  type = string
  description = "The name of the AWS credentials profile we will use."
  default = "lab2022"
}

variable "aws_region" {
  type = string
  description = "The name of the AWS Region we'll launch into."
  default = "us-east-1"
}

variable "environment" {
  type = string
  description = "The name of the environment we'd like to launch."
  default = "production"
}

variable "repository_url" {
  type = string
  description = "The url of the ECR repository we'll draw our images from."
}

variable "public_key_path" {
  type = string
  description = "The public key that will be used to allow ssh access to the bastions."
  sensitive = true
}
