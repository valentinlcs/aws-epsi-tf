provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

 

resource "aws_subnet" "public-a" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "10.0.1.0/24"

 

  tags = {
    Name = "public-a-tf"
  }
}

 

resource "aws_subnet" "public-b" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "10.0.2.0/24"

 

  tags = {
    Name = "public-b-tf"
  }
}

 

resource "aws_subnet" "private-a" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "10.0.3.0/24"

 

  tags = {
    Name = "private-a-tf"
  }
}

 

resource "aws_subnet" "private-b" {
  vpc_id     = aws_vpc.default.id
  cidr_block = "10.0.4.0/24"

 

  tags = {
    Name = "private-b-tf"
  }
}

 

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "terraform"
  }
}

 


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id

 

  tags = {
    Name = "igw-tf"
  }
}


resource "aws_route_table" "r" {
    vpc_id = aws_vpc.default.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id=aws_internet_gateway.gw.id
    }
    
    tags= {
        Name = "internet-tf"
    }
}

resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.public-a.id
    route_table_id = aws_route_table.r.id
} 

resource "aws_route_table_association" "b" {
    subnet_id = aws_subnet.public-b.id
    route_table_id = aws_route_table.r.id
}

resource "tls_private_key" "key" {
  algorithm   = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "deployer" {
    key_name = "ec2-key-tf"
    public_key = tls_private_key.key.public_key_openssh
}

resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.public-b.id
  associate_public_ip_address=true
  key_name = aws_key_pair.deployer.id
  user_data = file("${path.module}/postinstall.sh")
  vpc_security_group_ids =  ["${aws_security_group.webtf.id}"]
  
  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_security_group" "webtf" {
  name        = "sg"
  description = "sg"
  vpc_id      = aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent=true
  
  filter {
    name="name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  
  filter {
    name = "virtualization-type"
    values=["hvm"]
  }
  
  owners = ["099720109477"]
}

output "private-key" {
    value = tls_private_key.key.private_key_pem
}

output "ami-value" {
  value = data.aws_ami.ubuntu.image_id
}