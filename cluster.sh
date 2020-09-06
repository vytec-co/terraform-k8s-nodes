git clone https://github.com/magic7s/terraform_aws_spot_instance.git
cd terraform_aws_spot_instance
terraform init
terraform apply

cd ..

git clone https://github.com/magic7s/ansible-kubeadm-contiv.git
cd ansible-kubeadm-contiv
cp ../terraform_aws_spot_instance/inventory .
# Edit inventory file with public ip addresses from terraform output
ansible-playbook -i inventory site.yml
