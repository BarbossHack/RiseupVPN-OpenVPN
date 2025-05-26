#!/bin/bash

set -eu

if ! command -v jq >/dev/null 2>&1; then
    echo "Please install jq to run this script."
    echo "  $ sudo apt install jq"
    echo "  $ sudo dnf install jq"
    exit 1
fi

ARGS=" $* "
VERB=1
if [[ "$ARGS" = *" -v "* ]]; then
    CURL_NO_SILENT=
    VERB=3
elif [[ "$ARGS" = *" -vvv "* ]]; then
    CURL_VERBOSE=1
    CURL_NO_SILENT=
    VERB=5
    set -x
fi

OVPN_CONF=riseup-ovpn.conf

echo "Please wait, riseup API can be very slow..."

# Download new VPN client certs (private and public keys)
if [ -n "${CURL_NO_SILENT+x}" ]; then echo "curl riseup certificate from https://api.black.riseup.net/3/cert"; fi
# shellcheck disable=SC2086
key_cert=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT--sS} --fail --connect-timeout 10 --retry 3 -H "Accept: text/html" https://api.black.riseup.net/3/cert)

# Copy the sample openvpn conf
cp riseup-ovpn.sample.conf $OVPN_CONF
sed -i '/^remote .*$/d' $OVPN_CONF
sed -i "s/^verb .*$/verb $VERB/g" $OVPN_CONF
key=$(echo "$key_cert" | sed -e '/BEGIN RSA/,/END RSA/!d')
cert=$(echo "$key_cert" | sed -e '/BEGIN CERTIFICATE/,/END CERTIFICATE/!d')
echo -e "\n<key>\n$key\n</key>" >>$OVPN_CONF
echo -e "\n<cert>\n$cert\n</cert>" >>$OVPN_CONF

if [[ "$ARGS" = *" --no-ipv6 "* ]]; then
    echo -e "\e[33;3mIPv6 disabled.\e[0m"
    echo '
pull-filter ignore "tun-ipv6"
pull-filter ignore "route-ipv6"
pull-filter ignore "ifconfig-ipv6"
pull-filter ignore "redirect-gateway"
block-ipv6
redirect-gateway def1' >>$OVPN_CONF
elif ! ip a | grep inet6; then
    echo -e "\e[33;3mIPv6 appears to be disabled on your host. You may want to explicitly disable it using --no-ipv6\e[0m"
fi

# Get the VPN IP list, and add them to openvpn conf
if [ -n "${CURL_NO_SILENT+x}" ]; then echo "curl riseup servers list from https://api.black.riseup.net/3/config/eip-service.json"; fi
# shellcheck disable=SC2086
gateways=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT--sS} --fail --connect-timeout 10 --retry 3 -H "Accept: application/json" https://api.black.riseup.net/3/config/eip-service.json | jq '.gateways')

for gateway_b64 in $(echo "$gateways" | jq -r '.[] | @base64'); do
    gateway=$(echo "$gateway_b64" | base64 --decode)
    ip_address=$(echo "$gateway" | jq -r '.ip_address')
    host=$(echo "$gateway" | jq -r '.host')
    location=$(echo "$gateway" | jq -r '.location')
    ports=$(echo "$gateway" | jq -r '.capabilities.transport[] | select( .type | contains("openvpn")) | .ports[]')
    for port in $ports; do
        sed -i "/^remote-random$/i remote $ip_address $port # $host ($location)" $OVPN_CONF
    done
done

echo "OpenVPN conf was created with success !"
echo -e "\e[36m$ sudo openvpn --config $OVPN_CONF\e[0m"
