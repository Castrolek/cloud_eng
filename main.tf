
terraform {
  backend "s3" {
    bucket = "kp-terraform-state-2026" # Nazwa nowego bucketa z kroku 1
    key    = "web-portfolio/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1" 
}
# 1. Tworzymy koszyk S3
resource "aws_s3_bucket" "moja_strona" {
  bucket = "moje-unikalne-portfolio-2026-xyz" # Musi być unikalna nazwa na świecie!
}

# 2. Konfigurujemy go jako stronę WWW
resource "aws_s3_bucket_website_configuration" "config" {
  bucket = aws_s3_bucket.moja_strona.id

  index_document {
    suffix = "index.html"
  }
}

# 3. Wyłączamy blokady publicznego dostępu (Security!)
resource "aws_s3_bucket_public_access_block" "dostep" {
  bucket = aws_s3_bucket.moja_strona.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 4. Dodajemy prosty plik HTML
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.moja_strona.id
  key          = "index.html"
  source = "index.html"
  content_type = "text/html"
  etag = filemd5("index.html")
}
resource "aws_s3_object" "style" {
  bucket = aws_s3_bucket.moja_strona.id
  key = "style.css"
  source = "style.css"
  content_type = "text/css"
  etag = filemd5("style.css")
  
}



# Tworzymy "tożsamość" dla CloudFront, aby mógł wejść do zamkniętego S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.moja_strona.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = "S3-Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

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

    viewer_protocol_policy = "redirect-to-https" # Automatyczna kłódka!
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# Wyświetlamy nowy adres strony w konsoli
output "cloudfront_url" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

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