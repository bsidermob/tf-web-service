import re
import json
import argparse
import ast

### This just outputs a JSON with DNS values
### Lauch with "prod" flag to get prod addresses

### Variables

route53_regions_list = ["au", "nz", "us"]
route53_services_list = ["finder"]
route53_environment_prefixes_list_dev = ["dev-", "sit-", "uat-", "hotfix-"]
route53_environment_prefixes_list_prod = ["", "staging-"]

#### End variables

# create dict
empty_dict = {}

# Load ELB URLs from dictionary
with open('elb-addresses.json', 'r+') as f:
    elbs_dict = json.load(f)
    # get rid of unicode 'u' characters
    elbs_dict = ast.literal_eval(json.dumps(elbs_dict))

# Enable argument parser
parser = argparse.ArgumentParser()
parser.add_argument("prod", nargs='?', help="use PROD ELB URLs")
parser.add_argument("non-prod", nargs='?', help="use non-PROD ELB URLs")
parser.add_argument("region", nargs='?', help="Use ELB URLs specific to region")
args = parser.parse_args()

### Loop (This isn't very good but does the job)
#for zone in route53_zone_ids_dev_dict.values():
for service in route53_services_list:
    for region in route53_regions_list:
        if region.startswith(args.region):
            for elb, elb_dns_name in elbs_dict.iteritems():
                if args.prod == "prod":
                    if elb.startswith(region + '_prod'):
                        for env in route53_environment_prefixes_list_prod:
                            record_name = env + service
                            empty_dict.update({record_name:elb_dns_name})
                else:
                    if elb.startswith(region + '_non_prod'):
                        for env in route53_environment_prefixes_list_dev:
                            record_name = env + service
                            empty_dict.update({record_name:elb_dns_name})


### Functions
parser.parse_args()
print str(empty_dict).replace('\'','\"')
