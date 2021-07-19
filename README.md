# Will's Teleport test

Date: 07/16/2021
Author: William Loy


## Overview

The objective of this project is to design and deploy a VPN protected web service that is only accessible via Keycloak user interface authentication.

### Goals

This project seeks to accomplish the following goals:

- Produce a minimum viable product
- Automated infrastructure deployment and configuration
- VPN protected web service access
- Username and password web based authentication

### System stack
This system uses the following technologies:

  Hosting provider: 		          AWS
  Server OS:			                Ubuntu
  Web Server: 			              NGINX
  VPN provider:			              Wireguard
  IAM provider: 			            Keycloak
  Infrastructure deployment:	    Terraformt
