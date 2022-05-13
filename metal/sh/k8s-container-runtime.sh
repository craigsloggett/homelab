#!/bin/sh
#
# k8s-container-runtime.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${CRIO_OS:=Debian_11}"
: "${CRIO_VERSION:=1.23}"

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

# Enable Overlay Networking
if ! grep -q 'overlay' /etc/modules-load.d/modules.conf; then
	printf '%s\n' "overlay" >> /etc/modules-load.d/modules.conf
fi

# Enable Bridge Networking
if ! grep -q 'br_netfilter' /etc/modules-load.d/modules.conf; then
	printf '%s\n' "br_netfilter" >> /etc/modules-load.d/modules.conf
fi

# Manually Load Kernel Modules
modprobe overlay
modprobe br_netfilter

# Enable iptables Filtering on the Bridge Network
if ! grep -q 'net.bridge.bridge-nf-call-iptables' /etc/sysctl.d/local.conf; then
	cat >> /etc/sysctl.d/local.conf <<- 'EOF'
	net.bridge.bridge-nf-call-iptables = 1
	net.bridge.bridge-nf-call-ip6tables = 1
	EOF
fi

# Enable IP Forwarding
if ! grep -q 'net.ipv4.ip_forward' /etc/sysctl.d/local.conf; then
	printf '%s\n' "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/local.conf
fi

# Reload Kernel Variables
sysctl --system

# Install Dependencies
apt-get install -y \
	curl \
	gnupg \
	apt-transport-https \
	ca-certificates

libcontainers_repo_url="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable"

# Download the Open Container Initiative Repository Key Ring
libcontainers_keyring="/usr/share/keyrings/libcontainers-archive-keyring.gpg"

rm -f "${libcontainers_keyring}"  # Remove existing to allow updates.
curl -L "${libcontainers_repo_url}/${CRIO_OS}/Release.key" \
	| gpg --dearmor -o "${libcontainers_keyring}"

# Add the Open Container Initiative Package Sources List
cat > /etc/apt/sources.list.d/libcontainers-sources.list <<- EOF
deb [signed-by=${libcontainers_keyring}] ${libcontainers_repo_url}/${CRIO_OS}/ /
EOF

# Download the Container Runtime Interface Repository Key Ring
crio_keyring="/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg"

rm -f "${crio_keyring}"  # Remove existing to allow updates.
curl -L "${libcontainers_repo_url}:/cri-o:/${CRIO_VERSION}/${CRIO_OS}/Release.key" \
	| gpg --dearmor -o "${crio_keyring}"

# Add the Container Runtime Interface Package Sources List
cat > /etc/apt/sources.list.d/cri-o-sources.list <<- EOF
deb [signed-by=${crio_keyring}] ${libcontainers_repo_url}:/cri-o:/${CRIO_VERSION}/${CRIO_OS}/ /
EOF

# Update the Apt Cache
apt-get update

# Upgrade the System
apt-get -y upgrade
apt-get -y autoremove

# Install the Container Runtime Interface
apt-get -y install cri-o cri-o-runc

# Install the Container Networking Plugins
apt-get -y install containernetworking-plugins

# Enable and Start the Container Runtime Interface
systemctl enable crio
systemctl start crio
