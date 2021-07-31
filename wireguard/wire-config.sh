#!/bin/bash
# get creds
#echo -n " - username: "; read username
#echo -n " - password: "; read -s password; echo

export pkey=$(cat /etc/wireguard/keys/privatekey)
echo $pkey

export server_ip=`curl icanhazip.com`
echo $server_ip

export peer_key=$(cat /tmp/peer-publickey)
echo $peer_key

envsubst < /etc/wireguard/config-temp.txt > /etc/wireguard/wg0.conf
