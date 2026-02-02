provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true 

  endpoints {
    s3 = "http://localhost:4566"
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
    ec2 = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "testowy_bucket_nowy" {
  bucket = "unikalna-nazwa-12345"
}

resource "aws_s3_bucket_public_access_block" "security_policy" {
  bucket = aws_s3_bucket.testowy_bucket_nowy.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.testowy_bucket_nowy.id
  rule{
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  
}

resource "aws_iam_user" "junior_dev" {
  name="Junior_dev_poznan"
}

resource "aws_iam_policy" "read_only_buckets" {
  name = "ReadOnlyS3Buckets"
  description = "Pozwala tylko na podgląd listy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
  
}
resource "aws_iam_user_policy_attachment" "dev_attach" {
  user = aws_iam_user.junior_dev.name
  policy_arn = aws_iam_policy.read_only_buckets.arn
  
}

resource "aws_vpc" "glowna_siec" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags={
    Name = "VPC-Poznan-Lab"
  }
}
resource "aws_subnet" "Podsiec_prywatna" {
  vpc_id = aws_vpc.glowna_siec.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Private_subnet"
  }
  
}