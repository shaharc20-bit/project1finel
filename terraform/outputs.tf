output "ssh_command" {
  value = "ssh -i $HOME\\.ssh\\aws-lab ubuntu@${module.server.public_ip}"
}

output "app_url" {
  value = "http://${module.server.public_ip}:5001"
}

output "jenkins_url" {
  value = "http://${module.server.public_ip}:8080"
}

output "argocd_url" {
  value = "https://${module.server.public_ip}:30443"
}
