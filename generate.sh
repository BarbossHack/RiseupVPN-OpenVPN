#!/usr/bin/env bash

set -eu

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

SORT_BY_FASTEST=false
if [[ "$ARGS" = *" --sort-by-fastest "* ]]; then
    SORT_BY_FASTEST=true
fi

OVPN_CONF=riseup-ovpn.conf

# Check requirements
if ! command -v jq >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v ip >/dev/null 2>&1; then
    echo -e "\e[31m[-] Please install the following requirements to run this script:\e[0m"
    echo "Debian    $ apt install -y jq curl iproute2"
    echo "Fedora    $ dnf install -y jq curl iproute"
    echo "Alpine    $ apk add jq curl iproute2"
    echo "OpenWrt   $ apk add jq curl iproute2"
    echo "Nixos     $ nix-shell -p jq curl iproute2"
    echo "Archlinux $ pacman -Sy --noconfirm jq curl iproute2"
    exit 1
fi

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
# Disable IPv6
pull-filter ignore "tun-ipv6"
pull-filter ignore "route-ipv6"
pull-filter ignore "ifconfig-ipv6"
pull-filter ignore "redirect-gateway"
block-ipv6
redirect-gateway def1' >>$OVPN_CONF
elif ! ip a | grep inet6 >/dev/null 2>&1; then
    echo -e "\e[33;3mIPv6 appears to be disabled on your host. You may want to explicitly disable it using --no-ipv6\e[0m"
fi

if [[ "$ARGS" = *" --no-dns-leak "* ]]; then
    echo -e "\e[33;3mAvoid using ISP dns servers.\e[0m"
    echo '
# Avoid using ISP dns servers
pull-filter ignore "block-outside-dns"
pull-filter ignore "dhcp-option"
dhcp-option DNS 1.1.1.1
script-security 2
up "/usr/bin/env bash -c '\''/etc/openvpn/update-resolv-conf $* || /etc/openvpn/up.sh $*'\''"
down "/usr/bin/env bash -c '\''/etc/openvpn/update-resolv-conf $* || /etc/openvpn/down.sh $*'\''"' >>$OVPN_CONF
fi

# Get the VPN IP list, and add them to openvpn conf
if [ -n "${CURL_NO_SILENT+x}" ]; then echo "curl riseup servers list from https://api.black.riseup.net/3/config/eip-service.json"; fi
# shellcheck disable=SC2086
gateways=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT--sS} --fail --connect-timeout 10 --retry 3 -H "Accept: application/json" https://api.black.riseup.net/3/config/eip-service.json | jq '.gateways')

if [[ $SORT_BY_FASTEST = true ]]; then
    echo "Sorting servers by fastest connection speed..."
fi

for gateway_b64 in $(echo "$gateways" | jq -r '.[] | @base64'); do
    gateway=$(echo "$gateway_b64" | base64 -d)
    ip_address=$(echo "$gateway" | jq -r '.ip_address')
    host=$(echo "$gateway" | jq -r '.host')
    # Replace spaces in $location with underscores to maintain equal word count in $remote
    location=$(echo "$gateway" | jq -r '.location' | sed "s/ /_/g")
    ports=$(echo "$gateway" | jq -r '.capabilities.transport[] | select( .type | contains("openvpn")) | .ports[]')

    if [[ $SORT_BY_FASTEST = true ]]; then
        ping=$(ping -c 5 $ip_address | tail -n 1 | awk '{print $4}' | cut -d '/' -f 2)
        echo "Found average ping to $host ($location): $ping ms"
    fi

    for port in $ports; do
	remote="remote $ip_address $port # $host ($location)"
	if [[ $SORT_BY_FASTEST == true ]]; then
		remote="$remote $ping ms"
	fi

	sed -i "/^remote-random$/i $remote" $OVPN_CONF
    done
done

if [[ $SORT_BY_FASTEST = true ]]; then
    sorted=$(grep "remote " $OVPN_CONF | sort -n -s -k 7 | sed 's/$/\\/')
    # Remove existing remote addresses and replace them with their sorted version
    sed -i "/remote/d" $OVPN_CONF
    sed -i "/# Riseup available servers/a $sorted" $OVPN_CONF
    sed -i "/remote/s/\\\//" $OVPN_CONF
fi

echo "OpenVPN conf was created with success !"
echo -e "\e[36m$ sudo openvpn --config $OVPN_CONF\e[0m"
