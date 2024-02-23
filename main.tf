provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index) // "10.0.0.0/24" & "10.0.1.0/24"
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "public" {
  count  = 2
  domain = "vpc"
}

resource "aws_nat_gateway" "public" {
  count         = 2
  allocation_id = aws_eip.public[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}

// private subnet
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.example.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index + 10) // "10.0.10.0/24" & "10.0.11.0/24"
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route" "private" {
  count                  = 2
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public[count.index].id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_id" "key_id" {
  keepers = {
    ami_id = tls_private_key.ssh.public_key_openssh
  }

  byte_length = 8
}

resource "aws_key_pair" "ssh" {
  key_name   = "key-${random_id.key_id.hex}"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_sensitive_file" "ssh_private" {
  content  = tls_private_key.ssh.private_key_pem
  filename = "${path.module}/ssh_private"
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

// SG
resource "aws_security_group" "public" {
  name   = "public"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      aws_vpc.example.cidr_block,
      "${trimspace(data.http.my_ip.response_body)}/32"
    ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "consul_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.ssh.key_name
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.public.id]

  tags = {
    Name = "consul_server"
  }

  user_data = templatefile("${path.module}/user_data/consul_server.tpl", {
    consul_license_txt = try(file(var.consul_lic_path), "")
  })
}

resource "aws_instance" "consul_esm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.ssh.key_name
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.public.id]

  tags = {
    Name = "consul_esm"
  }

  user_data = templatefile("${path.module}/user_data/consul_esm.tpl", {
    consul_addr = "http://${aws_instance.consul_server.private_ip}:8500"
    lambda_url = aws_lambda_function_url.unhealty_service.function_url
  })
}

resource "aws_instance" "target" {
  depends_on = [aws_route.private]
  count      = 2

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.ssh.key_name
  subnet_id                   = aws_subnet.private[0].id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.public.id]

  tags = {
    Name = "instance-${count.index}"
  }

  user_data = templatefile("${path.module}/user_data/target_nginx_data.tpl", {
  })
}

locals {
  consul_addr = "http://${aws_instance.consul_server.public_ip}:8500"
  server_info = { for instance in aws_instance.target : instance.tags.Name => {
    name = instance.tags.Name
    id   = instance.id
    ip   = instance.private_ip
    }
  }
}

### Consul API
resource "local_file" "catalog_regist" {
  for_each = local.server_info
  content = templatefile("${path.module}/template/external_regist.tpl", {
    id      = each.value.id,
    uuid    = uuid()
    ip      = each.value.ip,
    port    = "80"
    service = replace(each.value.ip, ".", "_")
    // service = each.value.name
  })
  filename = "${path.module}/service/${each.value.id}_regist.json"
}

resource "local_file" "catalog_deregist" {
  for_each = local.server_info
  content = templatefile("${path.module}/template/external_deregist.tpl", {
    id      = each.value.id
    service = replace(each.value.ip, ".", "_")
  })
  filename = "${path.module}/service/${each.value.id}_deregist.json"
}

resource "checkmate_http_health" "consul" {
  url                   = "${local.consul_addr}/v1/status/leader"
  method                = "GET"
  timeout               = 100000
  interval              = 100
  status_code           = 200
  consecutive_successes = 2
}

resource "terraform_data" "catalog_regist" {
  depends_on = [checkmate_http_health.consul]
  for_each   = local.server_info

  triggers_replace = [timestamp()]

  input = {
    consul_addr          = local.consul_addr
    deregister_data_file = local_file.catalog_deregist[each.key].filename
  }

  provisioner "local-exec" {
    command = <<-EOF
      curl --request PUT \
        --data @${local_file.catalog_regist[each.key].filename} \
        ${local.consul_addr}/v1/catalog/register
    EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      curl --request PUT \
        --data @${self.input.deregister_data_file} \
        ${self.input.consul_addr}/v1/catalog/deregister
    EOF
  }
}

// Lambda
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "lambda"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid    = "lambda"
    effect = "Allow"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface",
      "ec2:DescribeSecurityGroups",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeSubnets",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "consul-lambda"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/node/index.js"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "unhealty_service" {
  filename      = data.archive_file.lambda.output_path
  function_name = "unhealthy-service"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      CONSUL_SERVER_PRIVATE_ADDR = "http://${aws_instance.consul_server.private_ip}:8500"
    }
  }

  vpc_config {
    subnet_ids = [aws_subnet.public[0].id]
    security_group_ids = [aws_security_group.public.id]
  }
}

resource "aws_lambda_function_url" "unhealty_service" {
  function_name      = aws_lambda_function.unhealty_service.function_name
  authorization_type = "NONE"
}