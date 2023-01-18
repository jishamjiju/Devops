# The default provider configuration; resources that begin with `aws_` will use
# it as the default, and it can be referenced as `aws`.
provider "aws" {
  region = "us-east-1"
  access_key = "AKIA5OK3YVO3GOYFGF6A" 
  secret_key = "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" 
}


# 1.create a vpc

resource "aws_vpc" "Prod_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "Product"
  }
  
}
# 2. Create a internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.Prod_vpc.id

  tags = {
    Name = "Prdouct internet gateway"
  }
}
# 3.create a CUstome route Table

resource "aws_route_table" "Prod-route-table" {
  vpc_id = aws_vpc.Prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}
# 4.Create a subnet

resource "aws_subnet" "Subnet-1" {
  vpc_id = aws_vpc.Prod_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "Prod-Subnet"
  }
  
}

# 5.Associate Subnet with ROute Table
resource "aws_route_table_association" "Prod-route-Associate" {
  subnet_id      =aws_subnet.Subnet-1.id
  route_table_id =aws_route_table.Prod-route-table.id
  
}
  
# 6.Create a Security group to allow port 22,,80,443

resource "aws_security_group" "allow-web-traffic" {
  name        = "web-traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.Prod_vpc.id

  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

 ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
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
    Name = "allow_web"
  }
}
# 7.Create a network Interferace with an ip inthe subnet that was created in the step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.Subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow-web-traffic.id]
 
}

# 8.Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "eip-Prod" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on =[aws_internet_gateway.gw]
}

# 9.Create Ubuntu server and isntalla/enable appache2

resource "aws_instance" "web-server-instance" {
  ami ="ami-0b0dcb5067f052a63"
  instance_type = "t2.micro" 
  availability_zone ="us-east-1a"
  key_name = "terra" 
    network_interface_id = aws_network_interface.web-server-nic.id
    
    }
user_data = 

  #!/bin/bash
sudo yum update -y
sudo yum install httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "The page was created by the user data" > /var/www/html/index.html
  
  }
