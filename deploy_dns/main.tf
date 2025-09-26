# ========================= #
# ======= DNS Module ====== #
# ========================= #
# Purpose
# Create DNS records as needed for all three deployment types

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

data "aws_route53_zone" "public-zone" {
  zone_id = var.zone_id
}

resource "aws_route53_record" "root-a" {
  zone_id = data.aws_route53_zone.public-zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.root_s3_distribution_domain_name
    zone_id                = var.root_s3_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www-a" {
  zone_id = data.aws_route53_zone.public-zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.www_s3_distribution_domain_name
    zone_id                = var.www_s3_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

