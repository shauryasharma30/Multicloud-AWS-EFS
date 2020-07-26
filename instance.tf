provider "aws" {
  region     = "ap-south-1"
  profile    = "task2"
}

resource "aws_key_pair" "key" {
key_name = "mykeytask2"
public_key="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAjl4x/ZdCZ1ykOdVNSzR9LcOo4hS1YZlDEOLu2LfX3SvlpxmeBh9HKn2VvEoHHLPoKGHNShtLf74M2J4XF1MKiCSxi5d+UZtv0125F3XqGVymVmKJFlOPvVfZ4tpu5hVWadVLl4IzQbbsnfK5Dy3vYZY/W+j/qv4Ps3QBm3HiRkURFFqxFLOexPMMNq3nk0DLArFv50CA2PpIFYZ+OnW+Uklf+6cpbQyWn3Qk0oZMUk2UxInfiyORLVkl3mU3BUDK9Hq8WUCjf/GB3Q0iGZo1rIIjL8tUdq3nK/9UWyShuWqMYyyW7uZ3ZVOeiBettc+keggulF/eI+apH+JSJfBvsw== rsa-key-20200611"
}

resource "aws_security_group" "task2sg" {
  name        = "add_rules"
  description = "Allow HTTP inbound traffic"
  vpc_id      = "vpc-ebe9f483"

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp" 
    cidr_blocks=["0.0.0.0/0"]
 }
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" 
    cidr_blocks=["0.0.0.0/0"]
 }
  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   egress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp" 
    cidr_blocks=["0.0.0.0/0"]
  }
   egress {
    description = "HTTP from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp" 
    cidr_blocks=["0.0.0.0/0"]
  }
  tags = {
    Name = "Task-2/SG"
  }
}

data "aws_vpc" "default" {
  default="true"
}
data "aws_subnet" "subnet" {
  vpc_id = data.aws_vpc.default.id
  availability_zone="ap-south-1a"
}

resource "aws_efs_file_system" "task2efs" {
  creation_token = "t2_efs"

  tags = {
    Name = "Persistent/EFS"
  }
}
resource "aws_efs_mount_target" "mount" {
  depends_on = [aws_efs_file_system.task2efs]
  file_system_id = aws_efs_file_system.task2efs.id
  subnet_id      = data.aws_subnet.subnet.id
  security_groups = [ aws_security_group.task2sg.id ]
}


resource "aws_instance" "inst" {
  ami           = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"
  key_name = "mykeytask2"
  vpc_security_group_ids=[aws_security_group.task2sg.id]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/shaurya/Downloads/task-key.pem")
    host     = aws_instance.inst.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo setenforce 0",
      "sudo yum install amazon-efs-utils -y",
      "sudo yum install nfs-utils -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
      ]
  }

  tags = {
    Name = "TASK-OS"
  }

}

resource "null_resource" "local1"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.inst.public_ip} > publicip.txt"
  	}
}


resource "null_resource" "remote2"  {

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/shaurya/Downloads/task-key.pem")
    host     = aws_instance.inst.public_ip
  }

provisioner "remote-exec" {
    inline = [
       "sudo mount -t efs ${aws_efs_file_system.task2efs.id}:/ /var/www/html",
       "echo '${aws_efs_file_system.task2efs.id}:/ /var/www/html efs _netdev 0 0' | sudo tee -a sudo tee -a /etc/fstab",
       "sudo rm -rf /var/www/html/*",
       "sudo git clone https://github.com/shauryasharma30/Multicloud-AWS-EFS.git /var/www/html/",
    ]
  }
}






