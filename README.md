# aws-postgres-cluster

## Know issues

- Terraform aws_ami data source [doesn't cache the AMI id](https://github.com/hashicorp/terraform/issues/13749). It does each time terraform recreates the aws_instance resource. To avoid that, I fixed the AMI id on terraform.

## References

- [Terraform - aws_security_group](https://www.terraform.io/docs/providers/aws/r/security_group.html)
- [Terraform - Data Source: aws_ami](https://www.terraform.io/docs/providers/aws/d/ami.html)
- [Terraform - Fix a wrong parameter which forces a instance recreation](https://github.com/hashicorp/terraform/issues/13749)
- [Ansible - Manages a Terraform deployment (and plans)](https://docs.ansible.com/ansible/devel/modules/terraform_module.html)