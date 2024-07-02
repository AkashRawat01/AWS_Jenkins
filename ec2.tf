# configured aws provider with proper credentials
provider "aws" {
  region    = "us-east-1"
  profile   = "Jenkins-user"
}


# create default vpc if one does not exit
# Create vpc

resource "aws_vpc" "Jenkins-vpc" {
  cidr_block = "192.0.0.0/16"
  tags = {
    Name = "Project-Jenkins-vpc"
  }
}


# 2. Create Internet Gateway

resource "aws_internet_gateway" "Jenkins-Gateway" {
  vpc_id = aws_vpc.Jenkins-vpc.id
  tags = {
     Name = "Jenkins-Internet-Gateway"
  }
}

# 3. Create Custom Route Table

resource "aws_route_table" "Jenkins-route-Table" {
  vpc_id = aws_vpc.Jenkins-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Jenkins-Gateway.id
  }
  tags = {
    Name = "Jenkins-Route-Table"
  }
}


# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}


# create default subnet if one does not exit
# Create a subnet

resource "aws_subnet" "Jenkins-subnet" {
  vpc_id = aws_vpc.Jenkins-vpc.id
  cidr_block = "192.0.1.0/24"
  availability_zone = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "Project-Jenkins-subnet"
  }
}

#2nd subnet
resource "aws_subnet" "Jenkins-2-subnet" {
  vpc_id = aws_vpc.Jenkins-vpc.id
  cidr_block = "192.0.2.0/24"
  availability_zone = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "Project-Jenkins-2-subnet"
  }
}


# associate route table with subnet-1
resource "aws_route_table_association" "my-Associate" {
  subnet_id      = aws_subnet.Jenkins-subnet.id
  route_table_id = aws_route_table.Jenkins-route-Table.id
}

# associate route table with subnet-2
resource "aws_route_table_association" "my-Associate-2" {
  subnet_id      = aws_subnet.Jenkins-2-subnet.id
  route_table_id = aws_route_table.Jenkins-route-Table.id
}

# create security group for the ec2 instance
resource "aws_security_group" "Jenkins_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 8080 and 22"
  vpc_id      = aws_vpc.Jenkins-vpc.id

  # allow access on port 8080
  ingress {
    description      = "http proxy access"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "http proxy access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # allow access on port 22
  ingress {
    description      = "ssh access"
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
  }

  tags   = {
    Name = "jenkins server security group"
  }
}


# create application load balancer
resource "aws_lb" "application_load_balancer" {
  name               = "Jenkins-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Jenkins_security_group.id]
  subnets            = [aws_subnet.Jenkins-subnet.id, aws_subnet.Jenkins-2-subnet.id]
  enable_deletion_protection = false

  tags   = {
    Name = "Jenkins-alb"
  }
}

# create target group
resource "aws_lb_target_group" "alb_target_group" {
  name        = "Jenkins-tg"
  target_type = "instance"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.Jenkins-vpc.id

  health_check {
    enabled             = true
    interval            = 300
    path                = "/"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}

##target group attachment
resource "aws_lb_target_group_attachment" "attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id = aws_instance.Jenkins-instance.id
}

# create a listener on port 80 with redirect action
resource "aws_lb_listener" "alb_http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

output "vpc_id" {
  value = aws_vpc.Jenkins-vpc.id
}

output "subnet1_id" {
  value = aws_subnet.Jenkins-subnet.id
}

output "subnet2_id" {
  value = aws_subnet.Jenkins-2-subnet.id
}

output "lb_dns_name" {
  value = aws_lb.application_load_balancer.dns_name
}

# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


# launch the ec2 instance and install website
resource "aws_instance" "Jenkins-instance" {
  ami                    = "ami-04b70fa74e45c3917"
  instance_type          = "c6a.large"  ##on-demand hourly-rate $0.076 vCPU 2 RAM 4 GiB EBS storage Up to 12500 Megabit Network performance
  subnet_id              = aws_subnet.Jenkins-subnet.id
  vpc_security_group_ids = [aws_security_group.Jenkins_security_group.id]
  key_name               = "tf-Jenkins"
  # user_data              = file("install_jenkins.sh")

  tags = {
    Name = "Jenkins-Server"
  }
}

# To enter EC2 instance to run the file and get the output
# an empty resource block
resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        ="ssh"
    user        = "ubuntu"
    private_key = "${file("${path.module}/tf-Jenkins.pem")}"
    host        = aws_instance.Jenkins-instance.public_ip
  }

  # copy the install_jenkins.sh file from your computer to the ec2 instance 
  provisioner "file" {
    source      = "install_Jenkins.sh"
    destination = "/home/ubuntu/install_Jenkins.sh"
  }

  # set permissions and run the install_Jenkins.sh file
  provisioner "remote-exec" {
    inline = [
        "sudo chmod +x /home/ubuntu/install_Jenkins.sh",
        "sudo /home/ubuntu/install_Jenkins.sh",
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.Jenkins-instance]
}


# print the url of the jenkins server
output "website_url" {
  value     = join ("", ["http://", aws_instance.Jenkins-instance.public_ip, ":", "8080"])
}

# print the url of Jenkins server with Load Balancer
output "LB_Website_URL" {
  value = join("", ["http://", aws_lb.application_load_balancer.dns_name])
}