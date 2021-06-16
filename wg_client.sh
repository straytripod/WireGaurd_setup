#!/bin/bash
#
# Script to configure wire gaurd vpn client.
#
# Settings and config files:
# /etc/wireguard/client-privatekey
# /etc/wireguard/client-publickey
# /etc/wiregaurd/wg0.conf
# /etc/ufw/before.rules
#
#  Server VPN IP: 10.10.10.1
#  Client VPN IP: 10.10.10.2
# Author: Straytripod
# 
echo "############################################################"
echo "## This will install and configure a WireGaurd VPN Clinet ##"
echo "############################################################"
echo "##   Internet <--> Server <-- 10.10.10.0/24 --> Client    ##"
echo "############################################################"
echo "############################################################"
echo "##   Server IP: 10.10.10.1/24                            ###"
echo "##   Client IP: 10.10.10.2/24                            ###"
echo "############################################################"
echo "Please review the script before running. You could lose access to this computer."
echo "Due to firewall changes."
read -p "Press any key to continue ..."
## Update / Upgrade
apt update && sudo apt upgrade -yy
## Install WireGaurd
apt install wireguard wireguard-tools -yy
## Create Keys
umask 077; wg genkey | tee /etc/wireguard/client-privatekey | wg pubkey > /etc/wireguard/clinet-publickey
## Set Var
client_priv=$(cat /etc/wireguard/client-privatekey)
echo""
echo""
echo "############################################################"
echo "Here is the private key:"
cat /etc/wireguard/client-privatekey
echo "############################################################"
echo "Here is the public key:"
cat /etc/wireguard/client-publickey
echo "############################################################"
echo""
echo""
sleep 10
apt install openresolv -yy
cp ./client_wg0.conf /etc/wireguard/wg0.conf
sed -i "/PrivateKey =/ s/$/$client_priv/" wg0.conf
echo""
echo "You will need to add the server public key to /etc/wiregaurd/wg0.conf"
echo "You will need to add the servers public IP as the endpoint"
echo""
sudo chmod 600 /etc/wireguard/ -R
echo"#############################################################################"
echo "You will need to add the server public key to /etc/wiregaurd/wg0.conf first"
echo "The servive can be started with the following commands:"
echo ""
echo "wg-quick up /etc/wireguard/wg0.conf"
echo "systemctl enable wg-quick@wg0.service"
echo "use 'wg' command to verify tunnel is up"
echo "############################################################################"
echo ""
sleep 5
systemctl status wg-quick@wg0.service
