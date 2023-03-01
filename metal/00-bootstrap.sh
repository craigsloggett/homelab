#!/bin/sh
#
# 00-bootstrap.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${USERNAME}"
: "${SSID}"
: "${SSID_PASSPHRASE}"
: "${ETH0_IP}"
: "${ETH0_BROADCAST:=10.0.1.255}"
: "${ETH0_NETWORK:=10.0.1.0}"

#
# Base OS
#

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

# Update the Debian Bullseye Sources List
cat > /etc/apt/sources.list <<- 'EOF'
	deb http://deb.debian.org/debian bullseye main contrib non-free
	deb http://deb.debian.org/debian bullseye-updates main contrib non-free
	deb http://deb.debian.org/debian bullseye-backports main contrib non-free
	deb http://security.debian.org/debian-security/ bullseye-security main contrib non-free
EOF

# Update the Apt Cache
apt-get update

# Add the Locale to Defaults
cat > /etc/default/locale <<- 'EOF'
	LANG=C.UTF-8
EOF

# Upgrade the System
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get -y autoremove

# Install the Hardware Device Drivers
apt-get install -y -t bullseye-backports \
	bluez-firmware \
	firmware-brcm80211 \
	wireless-regdb

# Update the Hosts File
hostname="$(hostname)"

cat > /etc/hosts <<- EOF
	127.0.0.1 ${hostname}.localdomain ${hostname}
	::1        ${hostname}.localdomain ${hostname} ip6-localhost ip6-loopback
	ff02::1    ip6-allnodes
	ff02::2    ip6-allrouters
EOF

# Install sudo
if ! command -v sudo; then
	apt-get install -y sudo
fi

cat > /etc/sudoers.d/no-password <<- 'EOF'
	# Allow members of group sudo to execute any command without a password
	%sudo ALL=(ALL:ALL) NOPASSWD:ALL
EOF

# Add a Regular User
if ! id "${USERNAME}" 2> /dev/null; then
	useradd -ms /bin/bash -G sudo "${USERNAME}"
fi

# Setup SSH
ssh_directory="/home/${USERNAME}/.ssh"
mkdir -p "${ssh_directory}"

cp /root/.ssh/authorized_keys "${ssh_directory}/authorized_keys"

chmod 700 "${ssh_directory}"
chmod 600 "${ssh_directory}/authorized_keys"
chown -R "${USERNAME}:${USERNAME}" "${ssh_directory}"

# Set vi as the Default Editor
update-alternatives --set editor /usr/bin/vim.tiny

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

# Setup Wired Local Networking
cat > /etc/network/interfaces.d/eth0 <<- EOF
	auto eth0
	iface eth0 inet static
	  address ${ETH0_IP}/24
	  broadcast ${ETH0_BROADCAST}
	  network ${ETH0_NETWORK}
	iface eth0 inet6 auto
EOF

# Reboot Nodes
printf '%s\n' "Rebooting nodes, next steps are to configure the OS for Kubernetes."

reboot