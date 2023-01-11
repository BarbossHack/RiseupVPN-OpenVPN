#!/bin/bash

set -e

# Download riseup CA
curl -s https://0xacab.org/leap/bitmask-vpn/-/raw/main/providers/riseup/riseup-ca.crt -o riseup-ca.crt
# Download new VPN client certs (private and public keys)
curl -s --cacert riseup-ca.crt https://api.black.riseup.net/3/cert -o riseup-vpn.pem
chmod 0600 riseup-vpn.pem

# Copy the sample openvpn conf
cp riseup.ovpn.sample.conf riseup.ovpn.conf
sed -i 's/^remote .*$//g' riseup.ovpn.conf

# Get the VPN IP list, and add them to openvpn conf
IP_LIST=$(curl -s --cacert riseup-ca.crt https://api.black.riseup.net/3/config/eip-service.json | jq -r .gateways[].ip_address)
for ip in $IP_LIST; do
    sed -i "/^remote-random$/i remote $ip 1194" riseup.ovpn.conf
done

echo "Ok"
