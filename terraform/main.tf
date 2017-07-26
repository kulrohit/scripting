provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

################# VPC Created #############################################
resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags {
        Name = "aws-vpc-created"
    }
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
}

################# Security groups for NAT #############################################
resource "aws_security_group" "nat_security_group" {
    name = "vpc_nat"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "NATSecurity_Group"
    }
}

################# AWS Subnet #############################################
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name =  "Subnet private for Terraform VPC"
  }
}


################# Security Group for ELB #############################################
resource "aws_security_group" "elb" {
  name        = "terraform_example_elb"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################# AWS ELB #############################################
resource "aws_elb" "web" {
  name = "terraform-example-elb"

  subnets         = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.ec2.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

################# Key Pair Authentication #############################################
resource "aws_key_pair" "auth" {
  key_name   = "pdx"
  public_key = "${file(var.aws_key_path)}"
}

################# EC2 Instance Creation #############################################
resource "aws_instance" "ec2" {
  connection {
    user = "ec2-user"
  }

  instance_type = "t1.micro"
  ami = "${lookup(var.amis, var.aws_region)}"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.elb.id}"]
  subnet_id = "${aws_subnet.default.id}"

   root_block_device {
    volume_type           = "gp2"
    volume_size           = 10
    delete_on_termination = true
}
     tags {
        Name = "Terraform-AWS-Instance-Created"
    }
  

}

################# Output #############################################


output "Instance_Created" {
  value = "Instance: ${element(aws_instance.ec2.*.id, 0)}"
}


################# Extra Code #############################################
#resource "aws_instance" "ec2" {
#  ami                         = "${lookup(var.amis, var.aws_region)}"
#  instance_type               = "t1.micro"
#  subnet_id                   = "${aws_subnet.default.id}"
#  associate_public_ip_address = true
#  private_ip                  = "10.0.28.150"
#}
