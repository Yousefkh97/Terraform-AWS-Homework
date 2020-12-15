# # 1. Create vpc - Virtual Private Cloud
resource "aws_vpc" "fursa" {
  cidr_block = "10.0.0.0/16"
}

# # 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.fursa.id
}

# # 3. Create Custom Route Table
resource "aws_route_table" "fursa-route-table" {
  vpc_id = aws_vpc.fursa.id

  route {
    cidr_block = "0.0.0.0/0" # IPv4
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0" #IPv6
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "fursa"
  }
}


# # 4. Create a Subnet 

resource "aws_subnet" "fursa-subnet1" {
  vpc_id            = aws_vpc.fursa.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "fursa1-subnet"
  }
}


resource "aws_subnet" "fursa-subnet2" {
  vpc_id            = aws_vpc.fursa.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-central-1b"
  tags = {
    Name = "fursa2-subnet"
  }
}

# Design to fail 
# # 5. Associate subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.fursa-subnet1.id
  route_table_id = aws_route_table.fursa-route-table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.fursa-subnet2.id
  route_table_id = aws_route_table.fursa-route-table.id
}

# # 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.fursa.id

  ingress {
    description = "HTTPS"
    from_port   = 443 # 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Docker"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name = "allow_web"
  }
}

# # 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic1" {
  subnet_id       = aws_subnet.fursa-subnet1.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.allow_web.id]
}

resource "aws_network_interface" "web-server-nic2" {
  subnet_id       = aws_subnet.fursa-subnet2.id
  private_ips     = ["10.0.10.10"]
  security_groups = [aws_security_group.allow_web.id]
}

# # 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic1.id
  associate_with_private_ip = "10.0.1.10"
  depends_on                = [aws_internet_gateway.gw]
}

output "server_public_ip1" {
  value = aws_eip.one.public_ip
}

resource "aws_eip" "two" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic2.id
  associate_with_private_ip = "10.0.10.10"
  depends_on                = [aws_internet_gateway.gw]
}

output "server_public_ip2" {
  value = aws_eip.two.public_ip
}

# # 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "web-server-instance" {
  ami               = "ami-0502e817a62226e03"
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1a"
  key_name          = "test"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic1.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install docker.io -y
                sudo docker pull yousefkh97/flaskapp
                sudo docker run -p 5000:5000  yousefkh97/flaskapp
                EOF
  tags = {
    Name = "web-server"
  }
}

# # Create a new Load Balancer
resource "aws_lb" "my-lb" {
  name               = "test-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = [aws_subnet.fursa-subnet1.id, aws_subnet.fursa-subnet2.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

# creat a new AWS target group
resource "aws_lb_target_group" "my-tg" {
  name     = "target"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.fursa.id
}

# Connect the load balncer to the target group 
resource "aws_lb_target_group_attachment" "my-tga" {
  target_group_arn = aws_lb_target_group.my-tg.arn
  target_id        = aws_instance.web-server-instance.id
  port             = 5000
}
 
