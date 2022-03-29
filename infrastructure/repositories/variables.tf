variable "aws_credentials_file" {
  type = string
  description = "The file that contains the AWS credentials we will use."
}

variable "aws_profile" {
  type = string
  description = "The name of the AWS credentials profile we will use."
}

variable "aws_region" {
  type = string
  description = "The name of the AWS Region we'll launch into."
}

variable "main_vpc_cidr" {
  type = string
  description = "VPC CIDR Notation"
}

variable "public_subnet_cidr" {
  type = string
  description = "Private subnet CIDR Notation"
}

variable "public_subnet_cidr" {
  type = string
  description = "Public subnet CIDR Notation"
}

# variable "availability_zone" {
#   type 
# }