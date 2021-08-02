#!/bin/bash
# get creds
#echo -n " - username: "; read username
#echo -n " - password: "; read -s password; echo
export wirekey=`curl http://login.southwindroast.com/api`
echo $wirekey

export mykey=`cat /path/local/privatekey`
echo $mykey

web_server=`terraform output -raw web_server_ip`
echo $web_server

envsubst < /path/local/wireguard-template.txt > /etc/wireguard/wg0.conf

sudo wg-quick up wg0
