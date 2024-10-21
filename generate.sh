#!/bin/bash

set -eu

# Verbose mode
if [ $# == 1 ] && [ "$1" == "-v" ]; then
    CURL_NO_SILENT=
elif [ $# == 1 ] && [ "$1" == "-vvv" ]; then
    CURL_VERBOSE=1
    CURL_NO_SILENT=
    set -x
fi

OVPN_CONF=riseup-ovpn.conf

echo "Please wait, riseup API can be very slow..."

# Download new VPN client certs (private and public keys)
if [ ! -z ${CURL_NO_SILENT+x} ]; then echo "curl riseup certificate from https://api.black.riseup.net/3/cert"; fi
key_cert=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT--sS} --fail --connect-timeout 10 --retry 3 -H "Accept: text/html" https://api.black.riseup.net/3/cert)

# Copy the sample openvpn conf
cp riseup-ovpn.sample.conf $OVPN_CONF
sed -i 's/^remote .*$//g' $OVPN_CONF
echo -e "\n<key>\n$key_cert\n</key>" >>$OVPN_CONF
echo -e "\n<cert>\n$key_cert\n</cert>" >>$OVPN_CONF

# Get the VPN IP list, and add them to openvpn conf
if [ ! -z ${CURL_NO_SILENT+x} ]; then echo "curl riseup servers list from https://api.black.riseup.net/3/config/eip-service.json"; fi
gateways=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT--sS} --fail --connect-timeout 10 --retry 3 -H "Accept: application/json" https://api.black.riseup.net/3/config/eip-service.json | jq '.gateways')

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

echo "OpenVPN conf was created with success !"
echo -e "\e[36m$ sudo openvpn --config $OVPN_CONF\e[0m"
