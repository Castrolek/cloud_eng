
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

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.moja_strona.id

  # TO JEST KLUCZ: Czeka aż blokady zostaną zdjęte
  depends_on = [aws_s3_bucket_public_access_block.dostep]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.moja_strona.arn}/*"
      },
    ]
  })
}