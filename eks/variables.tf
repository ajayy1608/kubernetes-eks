variable "desired_capacity" {
  default = "1"
}

variable "max_size" {
  default = "6"
}

variable "min_size" {
  default = "1"
}

variable "cluster-name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_vpc_net_id" {
  type = string
}

variable "aws_private_subnet_ids" {
  type = list(string)
}

variable "aws_subnet_ids" {
  type = list(string)
}

variable "aws_image_id" {
  type = string
}

variable "team_name" {
  type = string
}

variable "team_owner" {
  type = string
}

variable "instance_type" {
  default = "t2.large"
}

variable "key_name" {
  default = "test-keypair"
}

variable "eks-version" {
  default = ""
}

