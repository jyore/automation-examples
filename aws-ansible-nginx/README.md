aws-ansible-nginx
-----------------

The goal of this example is to have a running nginx instance on AWS EC2 using purely Ansible.


# Introduction

This example will launch a minimal web infrastructure into AWS, including the following resources:

* VPC w/ internet gateway and router
* Security Group
* EC2 Instance

It will run then use ansible to provision the EC2 Instance to run nginx and server a simple web page on port 80.

> **Note**: Ansible has the ability to function as both an infrastructure as code tool and a configuration management tool. This allows for a single tool to launch infrastructure and provision the servers that were launched. 


# Setup

The following steps are required in order to run this exampled:

* Ensure python, setup-tools, and python-pip are installed on your system (virtualenv is highly recommended)
* Install ansible and boto by running
~~~
$ pip install ansible boto boto3
~~~

* Create or Upload a keypair to AWS EC2 Key Pairs for logging into the instance with
* Create your AWS Access Keys in IAM fo the account you are wishing to deploy to and run the following:

~~~
$ export AWS_ACCESS_KEY_ID=<aws-access-key>
$ export AWS_SECRET_ACCESS_KEY=<aws-secret-access-key>
~~~

* Open the `vars/aws.yaml` file and assign desired values to each variable


This should complete the setup of the environment and you can now run the example.


# Running the Example

Infrastructure and server provisioning are separated into 2 playbooks. 

To build the infrastructure, run the following
~~~
$ ansible-playbook -i ec2.py standup.yaml
~~~

This will create all of the AWS infrastructure, but will not yet provision the instance. To provision the instance, wait a short time after the completion of the standup playbook, and then run
~~~
$ ansible-playbook -i ec2.py provision.yaml
~~~

This will setup nginx on the server and make sure the "Hello, World" website is available. You can retrieve the server IP address from the host listing in the `PLAY RECAP` section of your ansible run. You can login into the server using your keypair and your ip address, if desired.
~~~
$ ssh centos@<ip-address>
~~~

After ansible provision playbook finishes, you can curl the IP address of the instance or browse to the ip address in your web browser and receive the webpage!
~~~
$ curl <ip-address>
<html><head><title>tf-puppet-nginx</title></head><body><h1>Hello, World</h1></body></html>
~~~


## Dynamic Inventory

In the example, you may have noticed that we are calling the `ec2.py` script using the `-i` flag. This instructs Ansible to run the `ec2.py` script to dynamically determine inventory. This script will look into your AWS environment, pull all of the resource data, and categorize each into a multitude of ansible groups that can be used for targetting applications or application groups.

If you look at the provision playbook, you can see the targetted hosts group is `tag_role_webapp`. This is a host group that is built from the dynamic inventory script, based on AWS resource tags. Ansible interprets tags into groups by using `tag_<tag-name>_<tag-value>`. The EC2 instance we are targetting has the tag name `role` and corresponding value `webapp`, so it is classified into the `tag_role_webapp` group.

If we had launched more instances with this tag, then more servers would be inventoried into this host group and provisioned. If you wish you wish to test this out, then open up `roles/aws/tasks/main.yaml`, find the `instance launched` task, and update the `exact_count` parameter to 2 or any number of instances you'd like to launch. When the provision is run, all of the instances launched will get the nginx and simple web page setup.


# Teardown

Now that the example has run, we can destroy the infrastructure by running another playbook
~~~
$ ansible-playbook -i ec2.py destroy.yaml
~~~

