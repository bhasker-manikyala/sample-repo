//creates a VPC by the name labs-VPC. Change the name parameter to your required name

resource "aws_vpc" "labs" {
  cidr_block = "172.16.0.0/16" #//change the cidr_block to your desired value, get the values from your ATFM else do not change it

  tags = {
    Name = "labs" #//change labs to your desired name
  }
}

resource "aws_subnet" "public-subnet" {
  count             = length(var.public-subnet)
  vpc_id            = aws_vpc.labs.id
  cidr_block        = element(var.public-subnet, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "labs-public-subnet ${count.index + 1}" #//change labs to your desired name
  }
}

resource "aws_subnet" "private-subnet" {
  count             = length(var.private-subnet)
  vpc_id            = aws_vpc.labs.id
  cidr_block        = element(var.private-subnet, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "labs-private-subnet ${count.index + 1}" #//change labs to your desired name
  }

}

resource "aws_subnet" "db-subnet" {
  count             = length(var.db-subnet)
  vpc_id            = aws_vpc.labs.id
  cidr_block        = element(var.db-subnet, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "labs-db-subnet ${count.index + 1}" #//change labs to your desired name
  }

}

resource "aws_subnet" "intranet-subnet" {
  count             = length(var.intranet-subnet)
  vpc_id            = aws_vpc.labs.id
  cidr_block        = element(var.intranet-subnet, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "labs-intranet-subnet ${count.index + 1}" #//change labs to your desired name
  }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.labs.id
  tags = {
    Name = "labs-internet-gateway" #//change labs to your desired name
  }

}

resource "aws_route_table" "igw-route" {
  vpc_id = aws_vpc.labs.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "igw-route"
  }
}

resource "aws_route_table_association" "public-subnet-igw-association" {
  count          = length(var.public-subnet)
  subnet_id      = element(aws_subnet.public-subnet[*].id, count.index)
  route_table_id = aws_route_table.igw-route.id
}

//creates a VPC by the name labs-VPC. Change the name parameter to your required 
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.labs.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_instance" "web-app" {
  depends_on             = [aws_subnet.private-subnet]
  ami                    = "ami-0d07675d294f17973"
  availability_zone      = element(var.azs, 0)
  # subnet_id              = element(var.private-subnet, 0)
  subnet_id              = aws_subnet.private-subnet [0].id
  instance_type          = "t2.micro" //change the instance type of your choice
  key_name               = var.labs
  vpc_security_group_ids = [aws_security_group.ssh-security-group.id, aws_security_group.web-access-security-group.id]
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = var.web-app-boot-disk
    tags = {
      name = "web-app-boot-disk"
      size = "50GB"
      type = "gp3"
    }
  }
  tags = {
    name = "web-app"
    type = "web-server"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo yum update -y
  sudo amazon-linux-extras install -y nginx1
  sudo systemctl enable nginx
  sudo systemctl start nginx
  EOF
}