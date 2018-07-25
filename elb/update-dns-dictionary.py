### This grabs Terraform's output and then updates ELB URLs in the dictionary

import subprocess
import json
from pprint import pprint
elb_dns_name = subprocess.check_output("~/terraform output elb_dns_name", shell=True).strip()


### Actions
print "Using " + elb_dns_name

if "-non-prod-" in elb_dns_name:
    print "updating non-prod URLs..."
    with open('../dns/elb-addresses.json', 'r+') as f:
        data = json.load(f)
        data['au_non_prod'] = elb_dns_name
        print "au_non_prod updated with " + elb_dns_name
        data['nz_non_prod'] = elb_dns_name
        print "nz_non_prod updated with " + elb_dns_name
        data['us_non_prod'] = elb_dns_name
        print "us_non_prod updated with " + elb_dns_name
        f.seek(0)
        f.write(json.dumps(data))
        #json.dump(data, f)
        f.truncate()
elif "-prod-" in elb_dns_name:
    print "updating PROD URLs..."
    with open('../dns/elb-addresses.json', 'r+') as f:
        data = json.load(f)
        data['au_prod'] = elb_dns_name
        print "au_prod updated with " + elb_dns_name
        data['nz_prod'] = elb_dns_name
        print "nz_prod updated with " + elb_dns_name
        data['us_prod'] = elb_dns_name
        print "us_prod updated with " + elb_dns_name
        f.seek(0)
        f.write(json.dumps(data))
        #json.dump(data, f)
        f.truncate()
else:
    print "ELB URL missing. Doing nothing"
