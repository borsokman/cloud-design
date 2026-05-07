# 1. Generate a private key
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# 2. Generate a self-signed certificate using the private key
resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name  = "microservices.local"
    organization = "My Study Project"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# 3. Import the generated certificate into AWS ACM
resource "aws_acm_certificate" "imported_cert" {
  private_key      = tls_private_key.private_key.private_key_pem
  certificate_body = tls_self_signed_cert.cert.cert_pem

  tags = {
    Name = "microservices-imported-cert"
  }
}