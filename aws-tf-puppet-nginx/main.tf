
variable "region"        { }
variable "key_name"      { }
variable "instance_type" { default = "t2.micro" }

provider "aws" { 
  region = "${var.region}"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "tf-puppet-nginx-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "tf-puppet-nginx-igw"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags {
    Name = "tf-puppet-nginx-subnet"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
  
  tags {
    Name = "tf-puppet-nignx-route_table"
  }
}

resource "aws_route" "r" {
  route_table_id         = "${aws_route_table.route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table_association" "subnet_a_to_igw" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.route_table.id}"
}


resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "Allow web traffic to nginx"

  # Allow tcp inbound traffic on port 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "nginx-sg"
  }
}

# This would normally only be allowed from trusted cidr blocks
# or trusted security groups. This example uses public internet
# for simplicity
resource "aws_security_group" "public_ssh_access" {
  name        = "public-ssh-access"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "Allow remote ssh access"

  # Allow tcp inbound traffic on port 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "public-ssh-access"
  }
}


data "aws_ami" "centos7" {
  most_recent = true
  owners      = ["679593333241"]
  
  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS*"]
  }
}

resource "aws_instance" "nginx" {
  ami                         = "${data.aws_ami.centos7.id}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${aws_subnet.subnet.id}"
  associate_public_ip_address = true
  key_name                    = "${var.key_name}"
  user_data                   = "${file("data/userdata.sh")}"
  vpc_security_group_ids      = [
    "${aws_security_group.nginx_sg.id}",
    "${aws_security_group.public_ssh_access.id}"
  ]

  tags {
    Name = "tf-puppet-nginx"
  }
}

output "ip" { value = "${aws_instance.nginx.public_ip}" }
