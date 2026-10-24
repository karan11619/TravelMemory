resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "travelmemory-vpc"
    Environment = "assignment"
  }
}


resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "travelmemory-public-subnet"
    Environment = "assignment"
  }
}


resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name        = "travelmemory-private-subnet"
    Environment = "assignment"
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "travelmemory-igw"
    Environment = "assignment"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "travelmemory-public-rt"
    Environment = "assignment"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "travelmemory-nat-eip"
    Environment = "assignment"
  }
}


resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "travelmemory-nat-gateway"
    Environment = "assignment"
  }

  depends_on = [aws_internet_gateway.main]
}



resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "travelmemory-private-rt"
    Environment = "assignment"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


resource "aws_security_group" "web" {
  name        = "travelmemory-web-sg"
  description = "Security group for TravelMemory web server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my public IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.37.192.114/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "travelmemory-web-sg"
    Environment = "assignment"
  }
}


resource "aws_security_group" "database" {
  name        = "travelmemory-database-sg"
  description = "Allow MongoDB access from web server only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MongoDB from web server"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "travelmemory-database-sg"
    Environment = "assignment"
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
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = "travelmemory-key"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  tags = {
    Name        = "travelmemory-web-server"
    Environment = "assignment"
  }
}




resource "aws_instance" "database" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.database.id]
  key_name               = "travelmemory-key"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = false

  tags = {
    Name        = "travelmemory-database-server"
    Environment = "assignment"
  }
}

