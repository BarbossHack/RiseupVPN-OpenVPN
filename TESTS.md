# Tests

To test the script on different operating systems:

1. run the corresponding docker (see below)
2. run `./generate.sh` (install requirements if asked)
3. install openvpn and run `openvpn --config riseup-ovpn.conf`
4. run `podman exec -it dns curl ipinfo.io`

## Fedora

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name dns docker.io/fedora:latest bash
```

## Ubuntu

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name dns docker.io/ubuntu:latest bash
```

## Alpine

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name dns docker.io/alpine:latest sh
```

## Archlinux

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name dns docker.io/archlinux:latest bash
```

## Nixos

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name dns docker.io/nixos/nix:latest bash
```

## Openwrt

```bash
podman run -it --privileged --rm --pull=newer --device /dev/net/tun -v $PWD:/data:Z --workdir=/data --name dns docker.io/albrechtloh/openwrt-docker:latest bash
```
