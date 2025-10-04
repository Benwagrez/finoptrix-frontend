output "hosted_zone_id" {
    value = data.aws_route53_zone.public-zone.id
}

