#!/bin/sh
#
# wireless.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${SSID}"
: "${SSID_PASSPHRASE}"

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

# Setup Wireless Networking
apt-get install -y iwd

mkdir -p /var/lib/iwd
mkdir -p /etc/iwd

cat > "/var/lib/iwd/${SSID}.psk" <<- EOF
	[Security]              
	Passphrase=${SSID_PASSPHRASE}
EOF

cat > /etc/iwd/main.conf <<- 'EOF'
	[General]
	EnableNetworkConfiguration=true
EOF

systemctl enable iwd
systemctl enable systemd-resolved

ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
