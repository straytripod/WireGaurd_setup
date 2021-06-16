#!/bin/bash
#
# Script to configure wire gaurd vpn server.
#
# Settings and config files:
# /etc/wireguard/server-privatekey
# /etc/wireguard/server-publickey
# /etc/wiregaurd/wg0.conf
# /etc/ufw/before.rules
#
#  Server VPN IP: 10.10.10.1
#  Client VPN IP: 10.10.10.2
# Author: Straytripod
# 
echo "############################################################"
echo "## This will install and configure a WireGaurd VPN Server ##"
echo "############################################################"
echo "##   Internet <--> Server <-- 10.10.10.0/24 --> Client    ##"
echo "############################################################"
echo "############################################################"
echo "##   Server IP: 10.10.10.1/24                            ###"
echo "##   Client IP: 10.10.10.2/24                            ###"
echo "############################################################"
echo "Please review the script before running. You could lose access to this computer."
echo "Due to firewall changes."
echo ""
echo ""
read -p "Press any key to continue ..."
get_ip=$(curl http://myip.dnsmadeeasy.com)
apt update && sudo apt upgrade -yy
apt install wireguard wireguard-tools -yy
umask 077; wg genkey | tee /etc/wireguard/server-privatekey | wg pubkey > /etc/wireguard/server-publickey
server_priv=$(cat /etc/wireguard/server-privatekey)
echo""
echo""
echo "############################################################"
echo "Here is the private key:"
cat /etc/wireguard/server-privatekey
echo "############################################################"
echo "Here is the public key:"
cat /etc/wireguard/server-publickey
echo "############################################################"
echo""
echo""
sleep 10
apt install openresolv -yy
# Need to create the config file
cp ./wg0.conf /etc/wireguard/wg0.conf
# add keys to file
sed -i "/PrivateKey =/ s/$/$server_priv/" wg0.conf
echo""
echo "You will need to add the client public key to /etc/wiregaurd/wg0.conf"
echo""
sleep 5
chmod 600 /etc/wireguard/wg0.conf
## Enable IP Forwarding 
echo "Enabling IP Forwarding"
cp /etc/sysctl.conf /etc/sysctl.conf.bk
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
echo "Enabling Firewall with port 22 allowed"
ufw allow 22/tcp
echo "Here are the interface names."
ip -o link show | awk -F': ' '{print $2}'
echo "The second one listed is typcally the main netowrk interface used."
echo "This interface will be assigned to IP Tables for NAT Filtering."
ip -o link show | awk -F'2: ' '{print $2}' | awk -F': ' '{print $1}'
echo "If this is not correct, Press ctrl + c to cancel"
read -p "Press any key to continue ..."
## Adding NAT rulles
cp /etc/ufw/before.rules /etc/ufw/before.rules.bk
NETIF=$(ip -o link show | awk -F'2: ' '{print $2}' | awk -F': ' '{print $1}')
# NAT table rules
echo "# NAT table rules" >> /etc/ufw/before.rules
echo "*nat" >> /etc/ufw/before.rules
echo ":POSTROUTING ACCEPT [0:0]" >> /etc/ufw/before.rules
echo "-A POSTROUTING -o "$NETIF" -j MASQUERADE" >> /etc/ufw/before.rules
echo "" >> /etc/ufw/before.rules
echo "# End each table with the 'COMMIT' line or these rules won't be processed" >> /etc/ufw/before.rules
echo "COMMIT" >> /etc/ufw/before.rules
# Add forwrding fo trused networks
echo "# allow forwarding for trusted network" >> /etc/ufw/before.rules
echo "-A ufw-before-forward -s 10.10.10.0/24 -j ACCEPT" >> /etc/ufw/before.rules
echo "-A ufw-before-forward -d 10.10.10.0/24 -j ACCEPT+"  >> /etc/ufw/before.rules
echo "COMMIT" >> /etc/ufw/before.rules
## Enable the firewall
ufw enable
systemctl restart ufw
echo "Here is the Masquerade rule we have defined."
iptables -t nat -L POSTROUTING
echo "Since the VPN server has been defined as the DNS server for client, we need to run a DNS resolver on the VPN server. We wil install the bind9 DNS server."
sleep 10
apt install bind9
systemctl restart bind9
systemctl status bind9
## Add allow-recursion to bind options
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bk
awk -i inplace '1;/listen-on-v6 { any; };/ { print "allow-recursion { 127.0.0.1; 10.10.10.0/24; };"}' /etc/bind/named.conf.options
systemctl restart bind9
echo "adding firewall allow rulles"
ufw insert 1 allow in from 10.10.10.0/24
ufw allow 51820/udp
wg-quick up /etc/wireguard/wg0.conf
systemctl enable wg-quick@wg0.service
systemctl status wg-quick@wg0.service



