#!/bin/sh
#
# k8s-control-plane.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${USERNAME}"

# Prepare the kubeadm.conf File
cat > /etc/kubernetes/kubeadm-config.yaml <<- 'EOF'
	apiVersion: kubeadm.k8s.io/v1beta3
	kind: ClusterConfiguration
	networking:
	  podSubnet: "10.244.0.0/16"
	controlPlaneEndpoint: "controller-0"

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
