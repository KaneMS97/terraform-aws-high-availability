resource "aws_autoscaling_group" "main_asg" {
  name                      = "practice-asg"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.public_aza.id, aws_subnet.public_azb.id]
  launch_template {
    id      = aws_launch_template.main_template.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.target_group.arn]
}

resource "aws_launch_template" "main_template" {
  name          = "test"
  instance_type = "t2.micro"
  image_id      = "ami-03cf5768bcc686a8c"

  user_data              = filebase64("${path.module}/user-data.sh")
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  health_check {
    path = "/"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      },
    ]
  })
}

data "aws_iam_policy_document" "ec2_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:AmazonSSMManagedInstanceCore"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "ec2_role_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  role = aws_iam_role.ec2_role.name
}
