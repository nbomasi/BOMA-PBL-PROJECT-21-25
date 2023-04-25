# Creating S3 bucket to backup terraform state file
# resource "aws_s3_bucket" "terraform_state2" {
#   bucket = "eks-boma-1985"
# }
# #s3 versioning
# resource "aws_s3_bucket_versioning" "s3_version" {
#   bucket = aws_s3_bucket.terraform_state2.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
# # encryption at rest
# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
#   bucket = aws_s3_bucket.terraform_state2.bucket

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

#Dynamo DB resource for locking and consistency checking
# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "terraform-locks"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }


#Configuring s3 bucket
terraform {
  backend "s3" {
    bucket = "eks-boma-1985"
    key    = "global/s3/terraform.tfstate"
    region = "us-west-2"
    #dynamodb_table = "terraform-locks"
    encrypt = true
  }
}