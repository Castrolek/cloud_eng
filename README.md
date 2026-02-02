# Local Cloud Infrastructure with Terraform & LocalStack

## 🚀 O projekcie
Projekt demonstruje wdrożenie bezpiecznej infrastruktury chmurowej w środowisku lokalnym. Wykorzystuje **Terraform** do automatyzacji oraz **LocalStack** do emulacji usług AWS.

## 🛠️ Wykorzystane technologie
* **Terraform** (Infrastructure as Code)
* **LocalStack** (AWS Cloud Emulator)
* **Docker** (Containerization)
* **IAM & S3** (AWS Services)

## 🔐 Zastosowane zabezpieczenia
* **S3 Public Access Block**: Blokada publicznego dostępu do danych.
* **S3 Encryption**: Szyfrowanie spoczynkowe AES-256.
* **IAM Least Privilege**: Użytkownik deweloperski z ograniczonymi uprawnieniami (tylko odczyt).

## 💻 Jak uruchomić?
1. Uruchom LocalStack: `docker run -it -p 4566:4566 localstack/localstack`
2. Inicjalizacja: `terraform init`
3. Wdrożenie: `terraform apply --auto-approve`