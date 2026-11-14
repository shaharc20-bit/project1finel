locals {
  jenkins_env = <<-EOT
    JENKINS_ADMIN_PASSWORD=${var.admin_password}
    DOCKERHUB_TOKEN=${var.dockerhub_token}
    GITHUB_TOKEN=${var.github_token}
  EOT
}

resource "terraform_data" "jenkins" {
  triggers_replace = [
    module.server.instance_id,
    sha256(local.jenkins_env),
    sha256(join("", [for f in fileset("${path.module}/jenkins", "*") : filesha256("${path.module}/jenkins/${f}")])),
  ]

  connection {
    type        = "ssh"
    host        = module.server.public_ip
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/aws-lab"))
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${path.module}/jenkins"
    destination = "/tmp"
  }

  provisioner "file" {
    content     = local.jenkins_env
    destination = "/tmp/jenkins.env"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for install.sh (user_data) to finish...'",
      "cloud-init status --wait > /dev/null 2>&1 || true",
      "sed -i 's/\\r$//' /tmp/jenkins/* /tmp/jenkins.env",
      "sudo bash /tmp/jenkins/setup.sh",
    ]
  }

  provisioner "local-exec" {
    command = "echo Jenkins is ready: http://${module.server.public_ip}:8080"
  }
}

# Argo CD Application: the app comes from the gitops/ folder
locals {
  argocd_app = replace(templatefile("${path.module}/argocd/flask-app.yaml.tftpl", {
    repo_url = var.gitops_repo
    path     = var.gitops_path
  }), "\r\n", "\n")
}

resource "terraform_data" "argocd_app" {
  depends_on = [terraform_data.jenkins]

  triggers_replace = [
    module.server.instance_id,
    sha256(local.argocd_app),
  ]

  connection {
    type        = "ssh"
    host        = module.server.public_ip
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/aws-lab"))
    timeout     = "5m"
  }

  provisioner "file" {
    content     = local.argocd_app
    destination = "/tmp/argocd-app.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f /tmp/argocd-app.yaml",
      "kubectl -n argocd get applications",
    ]
  }
}
