apt update && sudo apt upgrade
apt install wireguard
umask 077; wg genkey | tee /etc/wireguard/server-privatekey | wg pubkey > /etc/wireguard/server-publickey
echo "Here is the private key:"
cat /etc/wireguard/server-privatekey
echo "Here is the public key:"
# Need to create the config file
