# The resources moved into modules. Terraform only renames them in the state,
# nothing is destroyed or created.

moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.main
}

moved {
  from = aws_subnet.public
  to   = module.network.aws_subnet.public
}

moved {
  from = aws_internet_gateway.main
  to   = module.network.aws_internet_gateway.main
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route_table_association.public
  to   = module.network.aws_route_table_association.public
}

moved {
  from = aws_security_group.server
  to   = module.server.aws_security_group.server
}

moved {
  from = aws_key_pair.lab
  to   = module.server.aws_key_pair.lab
}

moved {
  from = aws_iam_role.server
  to   = module.server.aws_iam_role.server
}

moved {
  from = aws_iam_role_policy.read_only
  to   = module.server.aws_iam_role_policy.read_only
}

moved {
  from = aws_iam_instance_profile.server
  to   = module.server.aws_iam_instance_profile.server
}

moved {
  from = aws_instance.server
  to   = module.server.aws_instance.server
}

moved {
  from = aws_eip.server
  to   = module.server.aws_eip.server
}
