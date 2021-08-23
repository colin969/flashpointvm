#!/bin/sh
if [ "$(id -u)" -ne "0" ]; then
	echo "Please run as root"
	exit 1
fi
if ! command -v qemu-img >/dev/null; then
	echo "Please ensure qemu-utils is installed"
	exit 1
fi
tmp=$(mktemp -u -t alpine.XXXXXX)
sh alpine-make-vm-image -f qcow2 -c "$tmp" setup.sh \
&& echo Shrinking image, please wait \
&& qemu-img convert -O qcow2 "$tmp" "$1" \
&& [ $SUDO_USER ] && chown "$SUDO_USER": "$1"
rm "$tmp"
