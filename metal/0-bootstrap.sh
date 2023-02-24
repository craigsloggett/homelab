#!/bin/sh
#
# 0-bootstrap.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${USERNAME}"
: "${CRIO_VERSION:=1.26}"

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
if ! id "${USERNAME}"; then
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

#
# Linux Kernel
#

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

# Enable IPVS
if ! command -v ipvsadm; then
	apt-get install -y ipvsadm ipset conntrack
fi

if ! grep -q 'ip_vs' /etc/modules-load.d/modules.conf; then
	cat >> /etc/modules-load.d/modules.conf <<- 'EOF'
		ip_vs
		ip_vs_rr
		ip_vs_wrr
		ip_vs_sh
		nf_conntrack
	EOF
fi

# Manually Load Kernel Modules
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack

# Reload Kernel Variables
sysctl --system

#
# Container Runtime
#

crio_os='Debian_11'
libcontainers_repo_url="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable"
libcontainers_keyring="/usr/share/keyrings/libcontainers-archive-keyring.gpg"
crio_keyring="/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg"

# Install Dependencies
apt-get install -y \
	curl \
	gnupg \
	apt-transport-https \
	ca-certificates

# Add the Open Container Initiative Package Sources List
cat > /etc/apt/sources.list.d/libcontainers-sources.list <<- EOF
	deb [signed-by=${libcontainers_keyring}] ${libcontainers_repo_url}/${crio_os}/ /
EOF

# Add the Container Runtime Interface Package Sources List
cat > /etc/apt/sources.list.d/cri-o-sources.list <<- EOF
	deb [signed-by=${crio_keyring}] ${libcontainers_repo_url}:/cri-o:/${CRIO_VERSION}/${crio_os}/ /
EOF

# Download the Open Container Initiative Repository Key Ring
rm -f "${libcontainers_keyring}" # Remove existing to allow updates.
curl -L "${libcontainers_repo_url}/${crio_os}/Release.key" |
	gpg --dearmor -o "${libcontainers_keyring}"

# Download the Container Runtime Interface Repository Key Ring
rm -f "${crio_keyring}" # Remove existing to allow updates.
curl -L "${libcontainers_repo_url}:/cri-o:/${CRIO_VERSION}/${crio_os}/Release.key" |
	gpg --dearmor -o "${crio_keyring}"

# Update the Apt Cache
apt-get update

# Upgrade the System
apt-get -y upgrade
apt-get -y autoremove

# Install the Container Runtime Interface
apt-get -y install cri-o cri-o-runc

# Enable and Start the Container Runtime Interface
systemctl enable crio

#
# Kubernetes (kubeadm)
#

kubernetes_repo_url="https://packages.cloud.google.com/apt/doc"
kubernetes_keyring="/usr/share/keyrings/kubernetes-archive-keyring.gpg"

# Add the Kubernetes Package Sources List
cat > /etc/apt/sources.list.d/kubernetes-sources.list <<- EOF
	deb [signed-by=${kubernetes_keyring}] https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Download the Kubernetes Repository Key Ring
rm -f "${kubernetes_keyring}" # Remove existing to allow updates.
curl -fsSLo "${kubernetes_keyring}" "${kubernetes_repo_url}/apt-key.gpg"

# Update the Apt Cache
apt-get update

# Upgrade the System
apt-get -y upgrade
apt-get -y autoremove

# Install the Kubernetes Components
apt-get -y install kubelet kubeadm kubectl

# Restart the Container Runtime Interface
systemctl restart crio

# Exclude the Kubernetes Packages from System Upgrades
apt-mark hold kubelet kubeadm kubectl

# Reboot Nodes
printf '%s%s\n' "Rebooting nodes, next steps are to initialize the cluster" \
	"from one of the control-plane nodes using kubectl."

reboot
