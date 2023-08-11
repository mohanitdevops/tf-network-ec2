provider "aws" {
    profile = "mohan-learn"
    region = "us-east-1"
}
variable "subnet_cidr" {
    description = "value of cidr"
}
#create vpc
resource "aws_vpc" "dev-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      name = "dev"
    }
}
#create igw
resource "aws_internet_gateway" "dev-gw" {
  vpc_id = aws_vpc.dev-vpc.id
  tags = {
    Name = "dev"
  }
}
#create custom route
resource "aws_route_table" "dev-rt" {
  vpc_id = aws_vpc.dev-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-gw.id
  }
  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.dev-gw.id
  }
  tags = {
    Name = "dev"
  }
}
#crate a subnet
resource "aws_subnet" "dev-aws_subnet-1" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.subnet_cidr[0].cidr_block
    availability_zone = "us-east-1a" 
    tags = {
        Name = var.subnet_cidr[0].name
    } 
}
resource "aws_subnet" "dev-aws_subnet-2" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = var.subnet_cidr[1].cidr_block
    availability_zone = "us-east-1b" 
    tags = {
        Name = var.subnet_cidr[1].name
    } 
}
#associate subnet with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.dev-aws_subnet-1.id
  route_table_id = aws_route_table.dev-rt.id
}
#create security group allow 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.dev-vpc.id
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "dev-sg"
  }
}
#create nic
resource "aws_network_interface" "dev" {
  subnet_id       = aws_subnet.dev-aws_subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
  tags = {
    Name = "dev"
  }
}
#create EIP and assing to nic
resource "aws_eip" "dev" {
#    vpc = true
    network_interface = aws_network_interface.dev.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [ aws_internet_gateway.dev-gw ]
}
output "server_public_ip" {
    value = aws_eip.dev.public_ip
  
}
#crate ubuntu server
resource "aws_instance" "web" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  network_interface {
    network_interface_id = aws_network_interface.dev.id
    device_index = 0
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                sudo apt-get install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo first app > /var/www/html/index.html'
                EOF
  tags = {
    Name = "dev"
  }
}
output "server_pri_ip" {
    value = aws_instance.web.private_ip
}
output "server_id" {
    value = aws_instance.web.instance_state
  
}