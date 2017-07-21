tf-puppet-nginx
---------------

The goal of this example is to have a running nginx instance on an AWS EC2 isntance using Terraform and Puppet.


# Introduction

This example will launch a minimal web infrastructure into AWS, including the following resources:

* VPC w/ internet router
* Security Group
* EC2 Instance

It will run a local puppet script to install and run an nginx server that listens on port 80 of the EC2 instance. 

> **Note**: In a real environment, a Puppet Master server would typically be deployed and configured to provide the compiled catalog to the EC2 instance. Additionally, the puppet agent on the instance would run periodically to enforce the configured state. This allows for consistent provisioning, correction of drift or tampering, and scalable configuration. The Puppet Master setup was omitted from this example for brevity and to remove complexity.


# Setup

The following steps are required in order to run this example:

* Ensure that Terraform downloaded and is on your file path. 
* Create or Upload a keypair to AWS EC2 Key Pairs for logging into the instance with
* Create your AWS Access Keys in IAM for the account you are wishing to deploy to and run the following:

~~~
$ export AWS_ACCESS_KEY_ID=<aws-access-key>
$ export AWS_SECRET_ACCESS_KEY=<aws-secret-access-key>
~~~

* Open the `terraform.tfvars` file and assign desired values to each variable


The should complete the setup of the environment and you can now run the example.



# Running the example

To run the example, run the following:

Generate a terraform plan:
~~~
$ terraform plan
~~~

Terraform plan gives a report of all infrastructure changes that will occur. It separates the report into resources that will be created, resources that are changing (and may require a full rebuild of the resource), and resources that are being removed. It is important to check these reports to make sure that there are no unwanted destructive changes and that the resources that are being created are correct.



Assuming the plan looks good, run the following to apply the changes:
~~~
$ terraform apply
~~~

After terraform completes, it should print the IP address of the created instance (see the output line at the end of the main script). Take note of this IP Address, as you will be using it momentarily. 


For example, `ip = 52.15.80.152`


When the instance is created, a bash script is run on the server. This script (located under `data/userdata.sh`) updates the operating system, installs puppet, installs the nginx puppet module, saves a puppet script, and then applies the puppet script. It will take some time for this operation to complete, but you can easily monitor the progress by logging into the instance and tailing the file that we push all the userdata script logs out to, `/var/log/userdata.log`.


You should be able to ssh into the isntance if you would like using the following:
~~~
$ ssh centos@<ip-address>
$ tail -f /var/log/userdata.log
~~~

Once it is complete, you should see that the Puppet script has executed and nginx will have been installed and configured to server a very basic "hello, world" message.
~~~
$ curl <ip-address>
<html><head><title>tf-puppet-nginx</title></head><body><h1>Hello, World</h1></body></html>
~~~


And if you browse to the ip address from your local machine, you should see the hello world message in your browser!


# Terdown

Now that the example has run, we can destroy the infrastructure in a single command
~~~
$ terraform destroy
~~~

You will be prompted to input `yes` to confirm the destruction of the resources.
