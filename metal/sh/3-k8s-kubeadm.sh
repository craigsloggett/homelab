#!/bin/sh
#
# k8s-kubeadm.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${CONTROL_IP:=192.168.1.110}"
: "${NODE_0_IP:=192.168.1.120}"
: "${NODE_1_IP:=192.168.1.121}"
: "${NODE_2_IP:=192.168.1.122}"

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

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

# Update the Hosts File with Cluster IPs
hostname="$(hostname)"

cat > /etc/hosts <<- EOF
	127.0.0.1 ${hostname}.localdomain ${hostname}
	::1        ${hostname}.localdomain ${hostname} ip6-localhost ip6-loopback
	ff02::1    ip6-allnodes
	ff02::2    ip6-allrouters

	${CONTROL_IP} controller-0
	${NODE_0_IP}  node-0
	${NODE_1_IP}  node-1
	${NODE_2_IP}  node-2
EOF
