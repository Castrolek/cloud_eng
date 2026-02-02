terraform {
  backend "s3" {
    bucket = "kp-terraform-state-2026"
    key    = "web-portfolio/terraform.tfstate"
    region = "eu-central-1"
  }
}

# Provider domyślny (Frankfurt)
provider "aws" {
  region = "eu-central-1"
}

# Provider pomocniczy (TYLKO dla certyfikatu SSL - musi być us-east-1)
provider "aws" {
  alias  = "virginia"
  region = "us-east-1" 
}

# Certyfikat SSL
resource "aws_acm_certificate" "cert" {
  provider          = aws.virginia
  domain_name       = "naukachmury.pl"
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
}

# 1. Koszyk S3
resource "aws_s3_bucket" "moja_strona" {
  bucket = "moje-unikalne-portfolio-2026-xyz"
}

# 2. Konfiguracja WWW
resource "aws_s3_bucket_website_configuration" "config" {
  bucket = aws_s3_bucket.moja_strona.id

  index_document {
    suffix = "index.html"
  }
}

# 3. Blokady dostępu
resource "aws_s3_bucket_public_access_block" "dostep" {
  bucket = aws_s3_bucket.moja_strona.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 4. Pliki strony
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.moja_strona.id
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
  etag         = filemd5("index.html")
}

resource "aws_s3_object" "style" {
  bucket       = aws_s3_bucket.moja_strona.id
  key          = "style.css"
  source       = "style.css"
  content_type = "text/css"
  etag         = filemd5("style.css")
}

# 5. CloudFront OAC
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 6. Dystrybucja CloudFront
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.moja_strona.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = "S3-Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["naukachmury.pl"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# 7. Polityka S3 (Tylko dla CloudFront)
resource "aws_s3_bucket_policy" "cloudfront_s3_policy" {
  bucket = aws_s3_bucket.moja_strona.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.moja_strona.arn}/*"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

# Outputy
output "cloudfront_url" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.s3_distribution.id
}