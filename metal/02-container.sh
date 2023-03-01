#!/bin/sh
#
# 0-bootstrap.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${CRIO_VERSION:=1.26}"

#
# Container Runtime
#

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

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
