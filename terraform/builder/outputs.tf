output "public_ip" {
  value       = aws_instance.builder.public_ip
  description = "Public IP of the builder instance"
}

output "ssh_private_key_path" {
  value       = local_file.private_key.filename
  description = "Path to the generated private SSH key (only the path is printed, not the key)"
}

output "ssh_key_name" {
  value       = aws_key_pair.builder_key.key_name
  description = "Name of the AWS SSH key pair"
}

output "security_group_id" {
  value       = aws_security_group.builder.id
  description = "ID of the builder security group"
}

output "ssh_command" {
  value       = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.builder.public_ip}"
  description = "Command to connect to the instance"
}

output "app_url" {
  value       = "http://${aws_instance.builder.public_ip}:5001"
  description = "Where the Flask app is reachable after it was started on the instance"
}
