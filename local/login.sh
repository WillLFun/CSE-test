#!/bin/bash
# get creds
#echo -n " - username: "; read username
#echo -n " - password: "; read -s password; echo
export wirekey=`curl http://login.southwindroast.com/api`
echo $wirekey
mykey=`/Users/will0342/Documents/terraform-project/learn-terraform-aws-instance/privatekey`
echo $mykey

envsubst < /Users/will0342/Documents/terraform-project/wireguard-test.txt > /etc/wireguard/wg0.conf
# test
#echo -n " - curl - "
#curl https://app.southwindroast.com
