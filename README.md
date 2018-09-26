# aws-postgres-cluster

## Requirements for execution

This project was tested using a ubuntu 18.04 as workstation/desktop

### Python virtual env

```text
dyego@ubuntu:~$ sudo apt install python-pip python-virtualenv
dyego@ubuntu:~$ virtualenv -p /usr/bin/python3 ~/python3-ansible
dyego@ubuntu:~$ source ~/python3-ansible/bin/activate
(python3-ansible) dyego@ubuntu:~$ pip install ansible
```

## Know issues

- Terraform aws_ami data source [doesn't cache the AMI id](https://github.com/hashicorp/terraform/issues/13749). It does each time terraform recreates the aws_instance resource. To avoid that, I fixed the AMI id on terraform. I kept the reference commented on the terraform file.

## References

- [Terraform - aws_security_group](https://www.terraform.io/docs/providers/aws/r/security_group.html)
- [Terraform - Data Source: aws_ami](https://www.terraform.io/docs/providers/aws/d/ami.html)
- [Terraform - Fix a wrong parameter which forces a instance recreation](https://github.com/hashicorp/terraform/issues/13749)
- [Ansible - Manages a Terraform deployment (and plans)](https://docs.ansible.com/ansible/devel/modules/terraform_module.html)