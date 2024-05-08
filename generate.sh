#!/bin/bash

set -eu

# Verbose mode
if [ $# == 1 ] && [ "$1" == "-v" ]; then
    VERBOSE=1
    set -x
fi

OVPN_CONF=riseup-ovpn.conf

echo -e "\e[30mPlease wait, riseup API is slow...\e[0m"

# Download new VPN client certs (private and public keys)
key_cert=$(curl ${VERBOSE:+-v} -sS --fail --connect-timeout 5 --retry 5 https://api.black.riseup.net/3/cert)

# Copy the sample openvpn conf
cp riseup-ovpn.sample.conf $OVPN_CONF
sed -i 's/^remote .*$//g' $OVPN_CONF
echo -e "\n<key>\n$key_cert\n</key>" >>$OVPN_CONF
echo -e "\n<cert>\n$key_cert\n</cert>" >>$OVPN_CONF

# Get the VPN IP list, and add them to openvpn conf
gateways=$(curl ${VERBOSE:+-v} -sS --fail --connect-timeout 5 --retry 5 https://api.black.riseup.net/3/config/eip-service.json | jq '.gateways')
for gateway_b64 in $(echo "$gateways" | jq -r '.[] | @base64'); do

    gateway=$(echo $gateway_b64 | base64 --decode)
    ip_address=$(echo $gateway | jq -r '.ip_address')
    host=$(echo $gateway | jq -r '.host')
    location=$(echo $gateway | jq -r '.location')
    ports=$(echo $gateway | jq -r '.capabilities.transport[] | select( .type | contains("openvpn")) | .ports[]')

    for port in $ports; do
        sed -i "/^remote-random$/i remote $ip_address $port # $host ($location)" $OVPN_CONF
    done
done

echo -e "\e[42m[+]\e[0m OpenVPN conf was created with success, you can now run:"
echo "sudo openvpn --config $OVPN_CONF"
