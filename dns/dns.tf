### This updates DNS records in Route53
###

### Make sure to switch to the right credential set below

provider "aws" {
  region                  = "ap-southeast-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "AU-prod"
}

# Non-prod
# This gets records from external Python script for AU
data "external" "records_dev_au" {
  program = ["python", "gen_list.py", "non-prod", "region", "au"]
}

# This gets records from external Python script for NZ
data "external" "records_dev_nz" {
  program = ["python", "gen_list.py", "non-prod", "region", "nz"]
}

# This gets records from external Python script for US
data "external" "records_dev_us" {
  program = ["python", "gen_list.py", "non-prod", "region", "us"]
}

# Prod
# This gets records from external Python script for prod AU
data "external" "records_prod_au" {
  program = ["python", "gen_list.py", "prod", "region", "au"]
}

# This gets records from external Python script for prod NZ
data "external" "records_prod_nz" {
  program = ["python", "gen_list.py", "prod", "region", "nz"]
}

# This gets records from external Python script for prod US
data "external" "records_prod_us" {
  program = ["python", "gen_list.py", "prod", "region", "us"]
}

### 'finder' URL
# Dev

# AU
resource "aws_route53_record" "finder-non-prod-au" {
count   = "${length(data.external.records_dev_au.result)}"
zone_id = "${lookup(var.route53_zone_ids_prod, "bizcover.com.au")}"
name    = "${element(keys(data.external.records_dev_au.result), count.index)}"
type    = "CNAME"
ttl     = "300"
records = ["${element(values(data.external.records_dev_au.result), count.index)}"]
}

/*
# NZ
resource "aws_route53_record" "finder-non-prod-nz" {
count   = "${length(data.external.records_dev_nz.result)}"
zone_id = "${lookup(var.route53_zone_ids_prod, "bizcover.co.nz")}"
name    = "${element(keys(data.external.records_dev_nz.result), count.index)}"
type    = "CNAME"
ttl     = "300"
records = ["${element(values(data.external.records_dev_nz.result), count.index)}"]
}

# US
resource "aws_route53_record" "finder-non-prod-us" {
count   = "${length(data.external.records_dev_us.result)}"
zone_id = "${lookup(var.route53_zone_ids_prod, "bizinsure.com")}"
name    = "${element(keys(data.external.records_dev_us.result), count.index)}"
type    = "CNAME"
ttl     = "300"
records = ["${element(values(data.external.records_dev_us.result), count.index)}"]
}

*/
# Prod
# AU
resource "aws_route53_record" "finder-prod-au" {
count   = "${length(data.external.records_prod_au.result)}"
zone_id = "${lookup(var.route53_zone_ids_prod, "bizcover.com.au")}"
name    = "${element(keys(data.external.records_prod_au.result), count.index)}"
type    = "CNAME"
ttl     = "300"
records = ["${element(values(data.external.records_prod_au.result), count.index)}"]
}

/*
# NZ
resource "aws_route53_record" "finder-prod-nz" {
count   = "${length(data.external.records_prod_nz.result)}"
zone_id = "${lookup(var.route53_zone_ids_prod, "bizcover.co.nz")}"
name    = "${element(keys(data.external.records_prod_nz.result), count.index)}"
type    = "CNAME"
ttl     = "300"
records = ["${element(values(data.external.records_prod_nz.result), count.index)}"]
}

# US
resource "aws_route53_record" "finder-prod-us" {
count   = "${length(data.external.records_prod_us.result)}"
zone_id = "${lookup(var.route53_zone_ids_prod, "bizinsure.com")}"
name    = "${element(keys(data.external.records_prod_us.result), count.index)}"
type    = "CNAME"
ttl     = "300"
records = ["${element(values(data.external.records_prod_us.result), count.index)}"]
}
*/
