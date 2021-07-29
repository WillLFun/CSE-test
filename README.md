# Will's Teleport Wirescale Project

Date: 07/16/2021
Author: William Loy


## Overview

This application deploys a web server behind Keycloak authentication and Wireguard VPN.

## Prerequisites

- AWS account
- Terraform installed locally
- AWS CLI installed locally
- AWS Access Keys

## Deployment instructions

1. Clone https://github.com/WillLFun/CSE-test

2. Edit all necessary variables.

2. `cd` to the cloned repository and run the following commands in this order:

    `make build`
    `terraform init`
    `terraform plan`

3. At this step you are asked for your AWS key name, leave it empty and press enter.
   Validate that the configuration is producing the expected result and then proceed to the next command.

4. From the CLI run the following command:

    `terraform apply`

5. At this step you should enter the AWS key name from your AWS account that corresponds with the region you have set to deploy the EC2 instance.

6. Follow the remaining prompts to complete the deployment.

7. Attempt to access domain.com/IP x.x.x.x.x

    - Enter username and password.

8. You should now be taken to the HTML page served by NGINX.
