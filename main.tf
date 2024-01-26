# Define the AWS provider
provider "aws" {
  region = "us-east-1" # Update with your desired region
}

# Create VPC
resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "example-vpc"
  }
}

# Create Public Subnet (for ALB)
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-az1"
  }
}

resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-az2"
  }
}

# Create Private Subnets (for ECS instances)
resource "aws_subnet" "private_subnet_az1" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "private-subnet-az1"
  }
}

resource "aws_subnet" "private_subnet_az2" {
  vpc_id                  = aws_vpc.example_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  tags = {
    Name = "private-subnet-az2"
  }
}

# Create ECS Cluster
resource "aws_ecs_cluster" "example_cluster" {
  name = "example-cluster"
}

# Create ALB
resource "aws_lb" "example_alb" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [] # Update with your security group IDs
  subnets            = [aws_subnet.public_subnet_az1.id, aws_subnet.public_subnet_az2.id]
}

# Create SSL Certificate (replace with your own ARN or use AWS ACM to generate)
variable "ssl_certificate_arn" {
  default = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-abcd-1234-abcd-1234abcd5678"
}

# Create HTTPS Listener
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.example_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
      message_body = "OK"
    }
  }

  certificate_arn = var.ssl_certificate_arn
}

# Create HTTP Listener with Redirect to HTTPS
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.example_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol      = "HTTPS"
      status_code   = "HTTP_301"
      port          = "443"
    }
  }
}

# Create ECS Task Definition (replace with your own configuration)
resource "aws_ecs_task_definition" "example_task" {
  # ...
}

# Create ECS Service
resource "aws_ecs_service" "example_service" {
  name            = "example-service"
  cluster         = aws_ecs_cluster.example_cluster.id
  task_definition = aws_ecs_task_definition.example_task.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets = [aws_subnet.private_subnet_az1.id, aws_subnet.private_subnet_az2.id]
    security_groups = [] # Update with your security group IDs
  }
}
