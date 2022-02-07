// aws launch configuration

resource "aws_launch_configuration" "awslaunch" {
  name = "awslaunchcfg"
  image_id = "ami-0a8b4cd432b1c3063"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.awsfw.id]
  associate_public_ip_address = true
  key_name = "awspublickey"
  user_data = var.userdata

}

//EC2 Firewall
resource "aws_security_group" "awsfw" {
  name = "aws-fw"
  vpc_id = aws_vpc.tfvpc.id
  
  ingress {
      from_port = 80
      protocol = "tcp"
      to_port = 80
      cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
      from_port = 22
      protocol = "tcp"
      to_port = 22
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port = 0
      protocol = "-1"
      to_port = 0
      cidr_blocks = ["0.0.0.0/0"]
  }
  
}

resource "aws_key_pair" "ssh" {
  key_name = "awspublickey"
  public_key = file("~/ec2test.pub")
}

resource "aws_autoscaling_group" "tfasg" {
  name = "tf-asg"
  max_size = 5
  min_size = 3
  launch_configuration = aws_launch_configuration.awslaunch.name
  vpc_zone_identifier = [aws_subnet.web1.id, aws_subnet.web2.id]
  target_group_arns = [aws_lb_target_group.pool.arn]

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "tf-ec2VM"
  }
}

//Network Load Balancer

resource "aws_lb" "nlb" {
  name = "tf-nlb"
  load_balancer_type = "network"
  enable_cross_zone_load_balancing = true
  subnets = [aws_subnet.web1.id, aws_subnet.web2.id]
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.nlb.arn
  port = 80
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.pool.arn
  }
}

resource "aws_lb_target_group" "pool" {
  name = "web"
  port = 80
  protocol = "TCP"
  vpc_id = aws_vpc.tfvpc.id
}

//network config

resource "aws_vpc" "tfvpc" {
  cidr_block = "172.20.0.0/16"

  tags = {
      name = "tf-vpc"
  }
}

resource "aws_subnet" "web1" {
    cidr_block = "172.20.10.0/24"
    vpc_id = aws_vpc.tfvpc.id
    availability_zone = "us-east-1a"

    tags = {
        name = "sub-web1"
    }
}
resource "aws_subnet" "web2" {
    cidr_block = "172.20.20.0/24"
    vpc_id = aws_vpc.tfvpc.id
    availability_zone = "us-east-1b"

    tags = {
        name = "sub-web2"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.tfvpc.id

    tags = {
        name = "igw"
    }
}

resource "aws_route" "tf-route" {
    route_table_id = aws_vpc.tfvpc.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
}