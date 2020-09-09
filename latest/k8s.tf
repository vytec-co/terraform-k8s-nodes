variable "ssh_key_name" {default = "ohio"}
provider "aws" {
  region = "us-west-2"
}
data "external" "myipaddr" {
  # Pick one or the other. The second one requires an external script but uses DNS instead of https.
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
  #program = ["bash", "${path.module}/myipaddr.sh"]
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
  vpc_security_group_ids = aws_security_group.k8s_sg.id
  key_name = var.ssh_key_name
  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s-worker" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  count         = "2"
  vpc_security_group_ids = aws_security_group.k8s_sg.id
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
  cidr_blocks     = data.external.myipaddr.result["ip"]/32
  description     = "Management Ports for K8s Cluster"

  security_group_id = aws_security_group.k8s_sg.id
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
  value = aws_instance.k8s-master.public_ip
}
output "worker_ips" {
  value = aws_instance.k8s-worker.*.public_ip
}
