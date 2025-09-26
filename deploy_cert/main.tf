# ========================= #
# ====== Cert Module ====== #
# ========================= #
# Purpose
# Create SSL certificates for: CloudFront distributions, 
# application loadbalancer, VM network traffic, 
# and container network traffic
#
# Pre-req
# Register domain name with AWS

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      configuration_aliases = [
        aws.east
      ]
      version = ">= 2.7.0"
    }
    acme = {
      source = "vancluever/acme"
      version = "2.16.1"
    }
  }
}


##############################################
### Domain Validated Cert Creation Process ###
##############################################

# Creating private key for acme registration
resource "tls_private_key" "registration" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Creating an account to register ourselves and our private key with the acme servers
resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.registration.private_key_pem
  email_address   = var.email_address
}

# Creating and validating a certificate
resource "acme_certificate" "certificates" {
  for_each = { for certificate in var.certificates : index(var.certificates, certificate) => certificate }

  common_name               = each.value.common_name
  subject_alternative_names = each.value.subject_alternative_names
  key_type                  = each.value.key_type
  must_staple               = each.value.must_staple
  min_days_remaining        = each.value.min_days_remaining
  certificate_p12_password  = each.value.certificate_p12_password
  account_key_pem              = acme_registration.registration.account_key_pem
  recursive_nameservers        = [ "ns-1506.awsdns-60.org", "ns-1993.awsdns-57.co.uk", "ns-628.awsdns-14.net", "ns-412.awsdns-51.com" ]
  disable_complete_propagation = false
  pre_check_delay              = 0

  # Certificate is validated against AWS DNS servers, must have DNS name registered with or configured for AWS
  dns_challenge {
      provider = "route53"
      config   = {
        AWS_ACCESS_KEY_ID     = var.AWS_ACCESS_KEY_ID
        AWS_SECRET_ACCESS_KEY = var.AWS_SECRET_ACCESS_KEY
        AWS_DEFAULT_REGION    = var.region
        AWS_HOSTED_ZONE_ID    = var.AWS_HOSTED_ZONE_ID
      }
    }
}

resource "aws_acm_certificate" "cert_east" {
  provider = aws.east 
  private_key        =  acme_certificate.certificates[0].private_key_pem   
  certificate_body   =  acme_certificate.certificates[0].certificate_pem 
  certificate_chain  =  acme_certificate.certificates[0].issuer_pem
  depends_on         =  [acme_certificate.certificates,tls_private_key.registration,acme_registration.registration]
}
