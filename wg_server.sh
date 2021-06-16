apt update && sudo apt upgrade -yy
apt install wireguard wireguard-tools -yy
umask 077; wg genkey | tee /etc/wireguard/server-privatekey | wg pubkey > /etc/wireguard/server-publickey
echo "Here is the private key:"
cat /etc/wireguard/server-privatekey
echo "Here is the public key:"
cat /etc/wireguard/server-publickey
apt install openresolv -yy
# Need to create the config file
cp ./wg0.conf /etc/wiregaurd/wg0.conf# NAT table rules
chmod 600 /etc/wireguard/wg0.conf
## Enable IP Forwarding 
Echo "Enabling IP Forwarding"
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
Echo "Enabling Firewall with port 22 allowed"
ufw allow 22/tcp
ufw enable
echo "Here are the interface names."
ip -o link show | awk -F'2: ' '{print $2}'
echo "The second one listed is typcally the main netowrk interface used."
echo "This interface will be assigned to IP Tables for NAT Filtering."
ip -o link show | awk -F'2: ' '{print $2}' | awk -F': ' '{print $1}'
echo "If this is not correct, Press ctrl + c to cancel"
pause
## Adding NAT rulles
NETIF=$(ip -o link show | awk -F'2: ' '{print $2}' | awk -F': ' '{print $1}')
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
