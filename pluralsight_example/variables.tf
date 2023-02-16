variable "aws_region" {
  type = string
  description = "AWS Region to use for resources"
  default = "ap-southeast-1"
}

variable "redundancy_count" {
  type = number
  description = "Redundancy count for networks and instances"
  default = 2
}

variable "vpc_subnets_cidr_block"{
  type = list(string)
  description = "CIDR blocks for subnets"
  default = ["10.0.0.0/24","10.0.1.0/24","10.0.2.0/24"]
}

variable "company" {
  type        = string
  description = "Company name for resource tagging"
  default     = "Globomantics"
}

variable "project" {
  type        = string
  description = "Project name for resource tagging"
}

variable "billing_code" {
  type        = string
  description = "Billing code for resource tagging"
}
