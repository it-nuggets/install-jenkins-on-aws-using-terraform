terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.10.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region =  var.aws_region
}

data "aws_ami" "amazon_linux" {
    most_recent = true
    owners      = ["amazon"]

    filter {
      name = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}

data "aws_iam_role" "existing_role" {
  name = "Terraform-aws-s3-project"
}



resource "aws_iam_instance_profile" "jenkins_project_profile" {
  name = "jenkins_project_profile"
  role = data.aws_iam_role.existing_role.name
}

resource "aws_instance" "jenskin-EC2" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.jenkins_sg_itnuggets.id]
    iam_instance_profile = aws_iam_instance_profile.jenkins_project_profile.name

    tags = {
      Name = var.name
    }

    user_data = <<-EOF
                sudo yum update –y
                sudo wget -O /etc/yum.repos.d/jenkins.repo \
                https://pkg.jenkins.io/redhat-stable/jenkins.repo
                sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
                sudo yum upgrade -y
                sudo dnf install java-17-amazon-corretto -y
                sudo yum install jenkins -y
                sudo systemctl enable jenkins
                sudo systemctl status jenkins
                sudo yum install git -y
                sudo yum install -y yum-utils -y
                sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
                sudo yum -y install terraform
                EOF
    
    lifecycle {
    create_before_destroy = true
    }
}
