# ========================= #
# ===== Main Executor ===== #
# ========================= #

locals {
  common_tags = {
    Owner = "benwagrez@gmail.com"
  }
}

#############################
###### Provider Config ######
#############################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "2.16.1"
    }
  }
}

# Acme provider for SSL certs for benwagrez.com
provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

# TLS provider for private key creation
provider "tls" {}

# AWS Provider
provider "aws" {
  region     = var.region
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

# AWS Provider for us-east-1
provider "aws" {
  alias      = "east"
  region     = "us-east-1"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

# Random module - TODO incorporate more randomness
provider "random" {
}


#############################
###### Module Manager #######
#############################

module "SSL_certification_deployment" {
  providers = {
    aws.east = aws.east
  }
  source = "./deploy_cert"

  region                = var.region
  email_address         = var.email_address
  AWS_ACCESS_KEY_ID     = var.AWS_ACCESS_KEY
  AWS_SECRET_ACCESS_KEY = var.AWS_SECRET_KEY
  AWS_HOSTED_ZONE_ID    = module.DNS_deployment.hosted_zone_id
  certificates          = var.certificates
}

module "DNS_deployment" {
  source = "./deploy_dns"

  domain_name     = var.domain_name
  zone_id         = var.hosted_zone_id
  
  root_s3_distribution_domain_name    = module.S3_website_deployment[0].root_cloudfront_domain_name
  root_s3_distribution_hosted_zone_id = module.S3_website_deployment[0].root_cloudfront_hosted_zone_id
  www_s3_distribution_domain_name     = module.S3_website_deployment[0].www_cloudfront_domain_name 
  www_s3_distribution_hosted_zone_id  = module.S3_website_deployment[0].www_cloudfront_hosted_zone_id
}

module "S3_website_deployment" {
  source = "./deploy_s3"

  acm_cert        = module.SSL_certification_deployment.acm_east_cert_arn
  domain_name     = var.domain_name
  common_tags     = local.common_tags
  TerraformSPNArn = data.aws_caller_identity.current.arn
} 

