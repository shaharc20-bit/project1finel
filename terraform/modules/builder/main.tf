data "aws_vpc" "selected" {
  id      = var.vpc_id != "" ? var.vpc_id : null
  default = var.vpc_id == "" ? true : null
}

data "aws_ec2_instance_type_offerings" "supported" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }

  filter {
    name   = "availability-zone"
    values = data.aws_ec2_instance_type_offerings.supported.locations
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"
  public_key = var.public_key
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "${var.name}: SSH, app, Jenkins, ingress and NodePorts from allowed IPs only"
  vpc_id      = data.aws_vpc.selected.id
}

resource "aws_security_group_rule" "tcp" {
  for_each = var.tcp_ports

  type              = "ingress"
  description       = each.value
  from_port         = tonumber(each.key)
  to_port           = tonumber(each.key)
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "nodeports" {
  count = var.open_nodeport_range ? 1 : 0

  type              = "ingress"
  description       = "Kubernetes NodePorts (Argo CD UI, qa service)"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidrs
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  description       = "All outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = sort(data.aws_subnets.public.ids)[0]
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = true

  user_data                   = var.user_data
  user_data_replace_on_change = true

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 3
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "builder"
  }
}
