#!/bin/sh
#
# k8s-control-plane.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${USERNAME}"
: "${CONTROLLER_IP:=192.168.1.110}"
: "${SERVICE_CIDR:=10.96.0.0/16}"
: "${POD_CIDR:=10.244.0.0/16}"

# Prepare the kubeadm.conf File
cat > /etc/kubernetes/kubeadm-config.yaml <<- EOF
	---
	apiVersion: kubeadm.k8s.io/v1beta3
	kind: InitConfiguration
	localAPIEndpoint:
	  advertiseAddress: "${CONTROLLER_IP}"
	  bindPort: 6443
	nodeRegistration:
	  criSocket: unix:///var/run/crio/crio.sock
	---
	apiVersion: kubeadm.k8s.io/v1beta3
	kind: ClusterConfiguration
	controlPlaneEndpoint: "${CONTROLLER_IP}:6443"
	networking:
	  serviceSubnet: "${SERVICE_CIDR}"
	  podSubnet: "${POD_CIDR}"
	  dnsDomain: "cluster.local"
	---
	apiVersion: kubeproxy.config.k8s.io/v1alpha1
	kind: KubeProxyConfiguration
	mode: "ipvs"
	ipvs:
	  strictARP: true
EOF

# Initialize the Control Plane
if [ ! -f /etc/kubernetes/admin.conf ]; then
	kubeadm init --config /etc/kubernetes/kubeadm-config.yaml
fi

# Copy the Kubeconfig to Access the Cluster
mkdir -p "/home/${USERNAME}/.kube"
cp -i /etc/kubernetes/admin.conf "/home/${USERNAME}/.kube/config"
chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.kube"

# Install a Network Add-on
printf '%s\n' "Before joining the nodes, install a Network Add-on."
