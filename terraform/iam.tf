
resource "aws_iam_role" "ec2_role" {
  name = "travelmemory-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = "assignment"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "travelmemory-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
