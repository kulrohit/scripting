variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {}


variable "aws_region" {
    description = "EC2 Region for the VPC"
    default = "ap-southeast-1"
}

variable "amis" {
    description = "AMIs by region"
    default = {
        ap-southeast-1 = "ami-011dc062" # centos
    }
}


variable "virtualization_type" {
  default = "hvm"
}


variable "vpc_cidr" {
   description = "CIDR for the whole VPC"
    default = "172.31.1.0/24"
}



variable "private_subnet_cidr" {
    description = "CIDR for the Private Subnet"
    default = "172.31.1.0/24"
}
