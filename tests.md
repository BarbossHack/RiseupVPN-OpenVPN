# Tests

## Fedora

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data docker.io/fedora:latest bash -c "dnf install -y jq curl iproute openvpn && ./generate.sh && (openvpn --config riseup-ovpn.conf &) && sleep 7 && curl -v --connect-timeout 10 ipinfo.io"
```

## Ubuntu

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data docker.io/ubuntu:latest bash -c "apt update && apt install -y jq curl iproute2 openvpn && ./generate.sh && (openvpn --config riseup-ovpn.conf &) && sleep 7 && curl -v --connect-timeout 10 ipinfo.io"
```

## Alpine

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data docker.io/alpine:latest sh -c "apk add bash jq curl iproute2 openvpn && ./generate.sh && (openvpn --config riseup-ovpn.conf &) && sleep 7 && curl -v --connect-timeout 10 ipinfo.io"
```

## Archlinux

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data docker.io/archlinux:latest bash -c "pacman -Sy --noconfirm jq curl iproute2 openvpn && ./generate.sh && (openvpn --config riseup-ovpn.conf &) && sleep 7 && curl -v --connect-timeout 10 ipinfo.io"
```

## Nixos

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data docker.io/nixos/nix:latest bash -c "nix-env -iA nixpkgs.jq nixpkgs.curl nixpkgs.iproute2 nixpkgs.openvpn nixpkgs.gnused && ./generate.sh && (openvpn --config riseup-ovpn.conf &) && sleep 7 && curl -v --connect-timeout 10 ipinfo.io"
```

## Openwrt

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data docker.io/albrechtloh/openwrt-docker:latest bash -c "apk add jq curl iproute2 openvpn && ./generate.sh && (openvpn --config riseup-ovpn.conf &) && sleep 7 && curl -v --connect-timeout 10 ipinfo.io"
```

## Gluetun

```bash
./generate.sh

podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name vpn -e VPN_SERVICE_PROVIDER=custom -e VPN_TYPE=openvpn -e OPENVPN_CUSTOM_CONFIG=/data/riseup-ovpn.conf docker.io/qmcgaw/gluetun:latest

podman exec -it vpn sh -c "apk add curl && curl ipinfo.io"
```
