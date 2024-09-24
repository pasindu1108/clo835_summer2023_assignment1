provider "aws" {
  region = "us-east-1"
}

# Create an Amazon ECR repository for the web application
resource "aws_ecr_repository" "webapp_repo" {
  name = "webapp"
}

# Create an Amazon ECR repository for the MySQL database
resource "aws_ecr_repository" "mysql_repo" {
  name = "mysql"
}

# Create a VPC
resource "aws_vpc" "default_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.default_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Create a security group that allows SSH, HTTP access
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.default_vpc.id
  name   = "allow_ssh_http"

  # Allow SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# Create an EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = "ami-0ebfd941bbafe70c6"  # Amazon Linux 2 AMI (update if needed)
  instance_type = "t2.micro"
  key_name      = "lab"

  tags = {
    Name = "WebAppserver"
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"               # Default user for Amazon Linux
    private_key = file("lab.pem")  # Path to your SSH private key
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -aG docker ec2-user"
    ]
  }
}

# Output the EC2 instance public IP and ECR URLs
output "ec2_instance_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}

output "ecr_webapp_url" {
  value = aws_ecr_repository.webapp_repo.repository_url
}

output "ecr_mysql_url" {
  value = aws_ecr_repository.mysql_repo.repository_url
}
