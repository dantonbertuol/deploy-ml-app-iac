output "instance_public_dns" {
  value = aws_instance.ml_api.public_dns
}
