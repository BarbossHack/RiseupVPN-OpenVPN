# check for sudo
if [ "$EUID" -ne 0 ]; then
	echo "Not using super cow powers :( ...exiting"
	exit 1
else
	echo "Running with super cow powers...continuing"
fi

# package manager array (feel free to fork this and let me know which other ones to add)
pkgmgr=("apt" "pacman" "dnf" "xbps-install")

# find the current package manager
for pm in ${pkgmgr[@]}; do
	command -v $pm >/dev/null 2>&1 && echo "Found $pm" && pm_found=$pm
done

case $pm_found in
	apt)
		echo "apt package manager detected...Ubuntu/Debian."
			apt update
			apt install -y openvpn jq
		;;
	pacman)
		echo "pacman package manager detected...you use Arch btw."
			pacman -Syu
			pacman -Sy openvpn jq
		;;
	dnf)
		echo "dnf package manager detected...I tip my hat to you."
			dnf update
			dnf install -y openvpn jq
		;;
	xbps-install)
		echo "xbps package manager detected...welcome to the Void."
			xbps-install -Syu
			xbps-install -Sy openvpn jq
		;;
	*)
		echo "None of the common package managers were detected...please run the install command for your package manager to install openvpn and jq."
		exit 1
		;;
esac

# get RiseupVPN keys and certs
curl -Os https://api.black.riseup.net/3/cert
curl -Os https://black.riseup.net/ca.crt

# get RiseupVPN JSON file
curl -Os https://api.black.riseup.net/3/config/eip-service.json

# initialize the riseup.ovpn config file
printf 'client\ndev tun\nproto tcp\nnobind\npersist-key\npersist-tun\npull-filter ignore "ping"\npull-filter ignore "ping-restart"\nkeepalive 10 20\nserver-poll-timeout 10\nconnect-retry 1 2\nconnect-retry-max 1\ncipher AES-256-GCM\ndata-ciphers AES-256-GCM\nremote-cert-tls server\nverb 3\nremote-random\n' > riseup.ovpn

# parse JSON with jq to get a list of the gateway IPs
parse_gateways=$(jq -r '.gateways[].ip_address' eip-service.json)

# add the gateways to the OpenVPN config file
for line in $parse_gateways; do
	echo "remote $line 1194"
done >> riseup.ovpn

# parse cert with awk to get the private key and cert
pk=$(echo "<key>" >> riseup.ovpn; awk '/-----BEGIN RSA PRIVATE KEY-----/,/-----END RSA PRIVATE KEY-----/' cert >> riseup.ovpn; echo "</key>" >> riseup.ovpn)
cert=$(echo "<cert>" >> riseup.ovpn; awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' cert >> riseup.ovpn; echo "</cert>" >> riseup.ovpn)
ca=$(echo "<ca>" >> riseup.ovpn; cat ca.crt >> riseup.ovpn; echo "</ca>" >> riseup.ovpn)

# add the private key and cers to the OpenVPN config file
echo -e "This has to run as sudo\n"
$pk; $cert; $ca

# launch openvpn using the newly built config file
echo -e "you have to run this as sudo\n"
openvpn --config riseup.ovpn
