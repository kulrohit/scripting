provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}



################# VPC Created #############################################
resource "aws_vpc" "default" {
#    cidr_block = "${var.vpc_cidr}"
     cidr_block = "172.31.1.0/24"
#    cidr_block = "${aws_vpc.default.id}"
   assign_generated_ipv6_cidr_block = false
    enable_dns_hostnames = true
    tags {
        Name = "terraform-aws-vpc-created"
    }
}

################# Internet Gateway #######################################
resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
}


################# AWS Subnet #############################################

resource "aws_subnet" "ap-southeast-1-private" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "172.31.1.0/24"
    availability_zone = "ap-southeast-1a"

    tags {
        Name = "Private Subnet"
    }
}

########################## Route add ######################################
#resource "aws_route_table" "r" {
#  vpc_id = "${aws_vpc.default.id}"

#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = "${aws_internet_gateway.default.id}"
#  }

  

#  tags {
#    Name = "main"
#  }
#}


###################Security Group##############################
resource "aws_security_group" "nat" {
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
        Name = "NATSG"
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

################# Security Group for ELB #############################################
resource "aws_elb" "web" {
  name = "elb-aws-with-terraform"

  subnets         = ["${aws_subnet.ap-southeast-1-private.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.nat.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"

  }
}


################# Key Pair Authentication #############################################
resource "aws_key_pair" "auth" {
  key_name   = "cb-demo"
  public_key = "${file(var.aws_key_path)}"
}


##################### Instance creation #################################################

resource "aws_instance" "nat" {
    ami = "ami-011dc062" # this is a special ami preconfigured to do NAT
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.micro"
    key_name = "${aws_key_pair.auth.id}"
    vpc_security_group_ids = ["${aws_security_group.nat.id}"]
    subnet_id = "${aws_subnet.ap-southeast-1-private.id}"
    associate_public_ip_address = true
    source_dest_check = false
    count = 2

    tags {
        Name = "Terraform_instance"
    }
}

################# Output #############################################


output "Instance_Created" {
  value = "Instance: ${element(aws_instance.nat.*.id, 0)}"
}


