#!/bin/sh
#
# 1-control-plane.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${USERNAME}"

# Prepare the kubeadm.conf File
cat > /etc/kubernetes/kubeadm-config.yaml <<- 'EOF'
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "192.168.1.110"
  bindPort: 6443
skipPhases:
  - addon/kube-proxy
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
controlPlaneEndpoint: "192.168.1.110:6443"
networking:
  serviceSubnet: "10.96.0.0/16"
  podSubnet: "10.32.0.0/16"
  dnsDomain: "cluster.local"
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
