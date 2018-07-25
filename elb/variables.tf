### Configurable variables

variable "alb_name" {
  default = "FILL_IN"
}

variable "sg_group_name" {
  default = "FILL_IN"
}

### finder.com.au cert
variable "https_cert_arn_prod" {
  default = "FILL_IN"
}

### bizcover.com.au cert
variable "https_cert_arn_non_prod" {
  default = "FILL_IN"
}

### Fixed variables

variable "subnets_prod" {
  type    = "list"
  default = ["subnet-", "subnet-"]
}

variable "subnets_non_prod" {
  type    = "list"
  default = ["subnet-", "subnet-"]
}

variable "vpc_prod_id" {
  default = "vpc-"
}

variable "vpc_non_prod_id" {
  default = "vpc-"
}

# sg_prod_app
variable "sg_prod_app_id" {
  default = "sg-"
}

# sg_nonprod_app
variable "sg_non_prod_app_id" {
  default = "sg-"
}

# These are access groups used to access resources from office
variable "sg_non_prod_additional_groups" {
  type    = "list"
  default = [
    "sg-",
    "sg-",
    "sg-"
  ]
}

variable "main_target_group_name" {
  default = "app1"
}

variable "websocket_target_group_name" {
  default = "websocket-app1"
}

variable "app_instance_id_prod" {
  default = "i-"
}

# au-npd-app1
variable "app_instance_id_non_prod" {
  default = "i-"
}
