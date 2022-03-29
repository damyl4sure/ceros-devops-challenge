# provider "aws" {
#     # Configuration options
#     alias = "lab2022"
#     region = "us-east-1"
# }

# terraform {
#     # Adding Backend as S3 for Remote State Storage
#     backend "s3" {
#         bucket = "ceros-devops-challenge"
#         key    = "challenge3/terraform.tfstate"
#         region = "us-east-1"
#         profile = "lab2022" #vital

#         # Enable state locking with AWS DynamoDB     
#         # For State Locking (LockID)
#         dynamodb_table = "ceros-devops-challenge-dynamodb"
#         #encrypt = true
#     }
# }