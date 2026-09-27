resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}



resource "aws_subnet" "public_aza" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_azb" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true
}

resource "aws_alb" "main_alb" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main_sg.id]
  subnets            = [aws_subnet.public_aza.id, aws_subnet.public_azb.id]

}
resource "aws_internet_gateway" "main_gateway" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_security_group" "main_sg" {
  name        = "main_sg"
  description = "Main Security Group"
  vpc_id      = aws_vpc.main_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.main_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "name" {
  security_group_id = aws_security_group.main_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gateway.id
  }
}

resource "aws_route_table_association" "aza_route_table" {
  route_table_id = aws_route_table.main_route_table.id
  subnet_id      = aws_subnet.public_aza.id
}

resource "aws_route_table_association" "azb_route_table" {
  route_table_id = aws_route_table.main_route_table.id
  subnet_id      = aws_subnet.public_azb.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.main_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "ec2 Security Group"
  vpc_id      = aws_vpc.main_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "tcp_alb" {
  security_group_id            = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.main_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "tcp_alb" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

