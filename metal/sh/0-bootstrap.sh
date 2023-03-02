#!/bin/sh
#
# bootstrap.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${USERNAME}"

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
	127.0.0.1  ${hostname}.localdomain ${hostname}
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
