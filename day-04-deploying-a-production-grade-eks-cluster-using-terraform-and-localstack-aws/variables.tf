variable "region" {
  type = string
  default = "us-east-2"
}


variable "az_1" {
  type = string
  default = "us-east-2a"
}


variable "az_2" {
  type = string
  default = "us-east-2b"
}


variable "tags" {
  type = map(string)
  default = {
    Name = "cloud-native-engineering-day-04"
    Environment = "Production"
    Team = "Operation Delta Force"
  }
}


variable "cidr_block" {
  type = string
  default = "10.0.0.0/16"
}


variable "cnel_public_subnet_one_cidr_block" {
  type = string
  default = "10.0.1.0/24"
}


variable "cnel_private_subnet_two_cidr_block" {
  type = string
  default = "10.0.2.0/24"
}


variable "cnel_public_subnet_three_cidr_block" {
  type = string
  default = "10.0.3.0/24"
}


variable "cnel_private_subnet_four_cidr_block" {
  type = string
  default = "10.0.4.0/24"
}