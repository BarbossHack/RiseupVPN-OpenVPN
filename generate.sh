#!/bin/bash

set -e
set -u

OVPN_CONF=riseup-ovpn.conf

# Download new VPN client certs (private and public keys)
curl -s --cacert riseup-ca.crt https://api.black.riseup.net/3/cert -o riseup-vpn.pem
chmod 0600 riseup-vpn.pem

# Copy the sample openvpn conf
cp riseup-ovpn.sample.conf $OVPN_CONF
sed -i 's/^remote .*$//g' $OVPN_CONF

# Get the VPN IP list, and add them to openvpn conf
IP_LIST=$(curl -s --cacert riseup-ca.crt https://api.black.riseup.net/3/config/eip-service.json | jq -r .gateways[].ip_address)
for ip in $IP_LIST; do
    sed -i "/^remote-random$/i remote $ip 1194" $OVPN_CONF
done

echo "[+] OpenVPN conf was created with success, you can now run :"
echo "sudo openvpn --config $OVPN_CONF"
