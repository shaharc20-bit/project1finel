output "instance_id" {
  value = module.builder.instance_id
}

output "public_ip" {
  value = module.builder.public_ip
}

output "public_dns" {
  value = module.builder.public_dns
}

output "security_group_id" {
  value = module.builder.security_group_id
}

output "ssh_key_name" {
  value = module.builder.key_name
}

output "ssh_command" {
  value = "ssh -i ${var.ssh_private_key_path} ubuntu@${module.builder.public_ip}"
}

output "app_url" {
  value = "http://${module.builder.public_ip}:5001"
}

output "app_ingress_url" {
  value = "http://${module.builder.public_ip}/"
}

output "jenkins_url" {
  value = "http://${module.builder.public_ip}:8080 (admin / admin_password)"
}

output "argocd_url" {
  value = "https://${module.builder.public_ip}:30443 (admin / admin_password)"
}

output "backup_location" {
  value = var.backup_bucket != "" ? "s3://${var.backup_bucket}/jenkins/" : "disabled"
}

output "allowed_cidrs" {
  value = local.allowed_cidrs
}
