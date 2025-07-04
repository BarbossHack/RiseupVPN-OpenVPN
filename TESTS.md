# Tests

To test the script on different operating systems:

1. run the corresponding docker (see below)
2. run `./generate.sh` (install requirements if asked)
3. install openvpn and run `openvpn --config riseup-ovpn.conf`
4. run `podman exec -it vpn curl ipinfo.io`

## Fedora

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name vpn docker.io/fedora:latest bash
```

## Ubuntu

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name vpn docker.io/ubuntu:latest bash
```

## Alpine

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name vpn docker.io/alpine:latest sh
```

## Archlinux

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name vpn docker.io/archlinux:latest bash
```

## Nixos

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name vpn docker.io/nixos/nix:latest bash
```

## Openwrt

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name vpn docker.io/albrechtloh/openwrt-docker:latest bash
```

## Gluetun

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name vpn -e VPN_SERVICE_PROVIDER=custom -e VPN_TYPE=openvpn -e OPENVPN_CUSTOM_CONFIG=/data/riseup-ovpn.conf docker.io/qmcgaw/gluetun:latest

podman exec -it vpn sh -c "apk add curl && curl ipinfo.io"
```
