provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "mlapp_bucket_flask" {
  bucket = "djb-108117563902-bucket" 

  tags = {
    Name        = "DJB Bucket"
    Environment = "ml-app"
  }

  provisioner "local-exec" {
    command = "${path.module}/upload_to_s3.sh"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws s3 rm s3://djb-108117563902-bucket --recursive"
  }
}

resource "aws_instance" "ml_api" {

  ami = "ami-0a0d9cf81c479446a"  

  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name

  vpc_security_group_ids = [aws_security_group.ml_api_sg.id]

  # Script de inicialização
  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y python3 python3-pip awscli
                sudo pip3 install flask joblib scikit-learn numpy scipy gunicorn
                sudo mkdir /ml_app
                sudo aws s3 sync s3://djb-108117563902-bucket /ml_app
                cd /ml_app
                nohup gunicorn -w 4 -b 0.0.0.0:5000 app:app &
              EOF


  tags = {
    Name = "MLFlaskApp"
  }
}

resource "aws_security_group" "ml_api_sg" {
  
  name        = "ml_api_sg"
  
  description = "Security Group for Flask App in EC2"

  ingress {
    description = "Inbound Rule 1"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Inbound Rule 2"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Inbound Rule 3"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound Rule"
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_s3_access_role" {
  
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole", # Permite que a instância assuma o papel
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "s3_access_policy" {
  
  name = "s3_access_policy"
  
  role = aws_iam_role.ec2_s3_access_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject", # Permite que a instância acesse o bucket
          "s3:PutObject", # Permite que a instância envie arquivos para o bucket
          "s3:ListBucket" # Permite que a instância liste os arquivos do bucket
        ],
        Effect = "Allow",
        Resource = [
          "${aws_s3_bucket.mlapp_bucket_flask.arn}/*",
          "${aws_s3_bucket.mlapp_bucket_flask.arn}"
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2_s3_profile"
  role = aws_iam_role.ec2_s3_access_role.name
}


