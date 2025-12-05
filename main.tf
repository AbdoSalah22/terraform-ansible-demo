terraform{
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
      }
    }
    backend "s3" {
        bucket = "my-devops-abdosalah"
        key    = "terraform/iac-cm-project/state.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform-locks"
        encrypt = true
    }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
    tags = {
        Name = "iac-cm-project-vpc"
    }
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
#   map_customer_owned_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
}

resource "aws_route_table_association" "a" {
    subnet_id      = aws_subnet.main_subnet.id
    route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "allow_web" {
    name        = "allow_web_traffic"
    vpc_id = aws_vpc.main_vpc.id

    ingress {
        description      = "SSH"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    ingress {
        description      = "HTTP"
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("./my-key.pub")
}

resource "aws_instance" "web_server" {
    ami           = "ami-0c1f44f890950b53c"
    instance_type = "t2.micro"
    key_name      = aws_key_pair.deployer.key_name
    subnet_id     = aws_subnet.main_subnet.id
    vpc_security_group_ids = [aws_security_group.allow_web.id]
    associate_public_ip_address = true

    tags = {
        Name = "ansible-managed-server"
    }    
}

resource "local_file" "ansible_inventory" {
  content = <<EOT
[webservers]
web1 ansible_host=${aws_instance.web_server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/my-key
EOT
  filename = "inventory.ini"
}

resource "null_resource" "run_ansible" {
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [ aws_instance.web_server, local_file.ansible_inventory ]
  
  provisioner "local-exec" {
    command = "sleep 30 && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${local_file.ansible_inventory.filename} playbook.yml"
  }
}

output "server_ip" {
  value = aws_instance.web_server.public_ip
}
