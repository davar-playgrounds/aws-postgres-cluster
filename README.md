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

### Inventory

You must keep the `inventories/inventory.conf` as default.

### Group Vars

Inside the `group_vars/` directory, you can find an example file. You must copy/move/rename it to `all.yml` after run the playbook. Further, you must configure vars there to playbook run.

```yaml
---
aws_access_key: put-here-your-access-key
aws_secret_key: put-here-your-secret-key
region: us-east-1
project_name: aws-pg-cls
vpc_cidr: 10.10.0.0/16
subnet1_cidr: 10.10.0.0/24
subnet2_cidr: 10.10.1.0/24
db_username: postgres
db_password: password
db_name: pgcls
email_host: smtp.mailtrap.io
email_host_user: user
email_host_password: password
email_port: 2525
email_default_sender: blacklist@paxful.test
```

## Know issues

- Terraform aws_ami data source [doesn't cache the AMI id](https://github.com/hashicorp/terraform/issues/13749). It does each time terraform recreates the aws_instance resource. To avoid that, I fixed the AMI id on terraform. I kept the reference commented on the terraform file.

## Improvements

- This playbook covers only Debian distribution, using module apt only, for example. It should be improved to cover other distributions.
- Avoid to include more than one master on `roles/pre_config_db/templates/*-pg_hba.conf.j2`, `roles/pre_config_db_slave/templates/recovery.conf.j2` and `roles/pre_config_db_slave/tasks/main.yml`.
- Include on terraform to change the rule 100 on default acl to a bigger number, because now we can have only 99 blacklisted IPs.

## References

- [Terraform - aws_security_group](https://www.terraform.io/docs/providers/aws/r/security_group.html)
- [Terraform - Data Source: aws_ami](https://www.terraform.io/docs/providers/aws/d/ami.html)
- [Terraform - Fix a wrong parameter which forces a instance recreation](https://github.com/hashicorp/terraform/issues/13749)
- [Ansible - Manages a Terraform deployment (and plans)](https://docs.ansible.com/ansible/devel/modules/terraform_module.html)
- [Postgres - Master/Slave](https://blog.raveland.org/post/postgresql_sr/)
- [Python - Flask + SQLAlchemy](http://blog.sahildiwan.com/posts/flask-and-postgresql-app-deployed-on-heroku/)
- [Python - Flask-Boto3](https://github.com/Ketouem/flask-boto3)
- [Python - Flask-Mail](https://pythonhosted.org/Flask-Mail/)