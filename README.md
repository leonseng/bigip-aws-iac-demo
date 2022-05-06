# BIG-IP AWS IaC Demo

This repository showcase how BIG-IP can be managed as Infrastructure as Code (IaC).

## Instructions

1. Create a `terraform.tfvars` file to override the default values in [variables.tf](./variables.tf), e.g.:
    ```
    # terraform.tfvars
    region            = us-east-1
    availabilityZones = [us-east-1a, us-east-1b]
    AllowedIPs        = ["0.0.0.0/0"]
    ```
1. Run the `terraform` commands to deploy the infrastructure
```
terraform init
terraform apply -auto-approve
```

Two BIG-IPs are deployed into an AWS VPC.
