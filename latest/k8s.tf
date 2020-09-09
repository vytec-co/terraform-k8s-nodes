variable "ssh_key_name" {default = "ohio"}
variable "aws_region_name" { default = "us-east-2" }
provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "k8s-master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  count         = "1"
  pc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name = var.ssh_key_name
  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s-worker" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  count         = "2"
  pc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name = var.ssh_key_name
  tags = {
    Name = "k8s-worker"
  }
}
resource "aws_security_group" "k8s_sg" {

}
resource "aws_security_group_rule" "allow_all_egress" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "all"
  cidr_blocks     = ["0.0.0.0/0"]
  description     = "Outbound access to ANY"

  security_group_id = aws_security_group.k8s_sg.id
}
resource "aws_security_group_rule" "allow_all_myip" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "all"
  cidr_blocks     = ["${data.external.myipaddr.result["ip"]}/32"]
  description     = "Management Ports for K8s Cluster"

  security_group_id = "${aws_security_group.k8s_sg.id}"
}

resource "aws_security_group_rule" "allow_SG_any" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "all"
  self            = true
  description     = "Any from SG for K8s Cluster"

  security_group_id = aws_security_group.k8s_sg.id
}

output "master_ip" {
  value = aws_spot_instance_request.k8s-master.public_ip
}
output "worker_ips" {
  value = aws_spot_instance_request.k8s-worker.*.public_ip
}
