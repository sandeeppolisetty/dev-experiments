resource "aws_vpc" "my-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = "${aws_vpc.my-vpc.id}"
}

resource "aws_subnet" "my-subnet-public-1" {
  vpc_id                  = "${aws_vpc.my-vpc.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
}

resource "aws_subnet" "my-subnet-private-1" {
  vpc_id                  = "${aws_vpc.my-vpc.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1a"
}

resource "aws_route_table" "my-public-crt" {
  vpc_id = "${aws_vpc.my-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.my-igw.id}"
}

resource "aws_iam_role" "ssm_role" {
  name = "ssm_role"
  path = "/"
}

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
  }
 EOF
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "SSM-role-policy-attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-role"
  role = aws_iam_role.ssm_role.name
}

resource "aws_security_group" "my-private_sg" {
  name        = "${var.name}-private-sg"
  description = "Security Group for Private EC2 instance"
  vpc_id      = "${aws_vpc.my-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "private_server" {
  ami                         = var.ami_id
  instance_type               = t3.micro
  key_name                    = var.key_name
  vpc_security_group_ids      = "${aws_security_group.my-private_sg.id}"
  subnet_id                   = "${aws_subnet.my-subnet-private-1.id}"
  iam_instance_profile        = "{aws_iam_instance_profile.ec2_instance_profile.name}"

  tags = {
    Name    = "private-server"
  }

  volume_tags = {
    Name    = "private-server-volume"
  }
}


