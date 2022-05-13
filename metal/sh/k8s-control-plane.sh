#!/bin/sh
#
# k8s-control-plane.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${CONTROL_PLANE_ENDPOINT:=192.168.1.110}"
: "${USERNAME}"

# Prepare the kubeadm.conf File
cat > /etc/kubernetes/kubeadm-init.yaml <<- EOF
# Use Default Init Configuration

# apiVersion: kubeadm.k8s.io/v1beta3
# kind: InitConfiguration

# ---

apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
controlPlaneEndpoint: "${CONTROL_PLANE_ENDPOINT}"

---

apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"

# Use Default Kubelet Configuration

# ---
# apiVersion: kubelet.config.k8s.io/v1beta1
# kind: KubeletConfiguration
EOF

# Initialize the Control Plane
if [ ! -f /etc/kubernetes/admin.conf ]; then
	kubeadm init --config /etc/kubernetes/kubeadm-init.yaml
fi

# Copy the Kubeconfig to Access the Cluster
mkdir -p "/home/${USERNAME}/.kube"
cp -i /etc/kubernetes/admin.conf "/home/${USERNAME}/.kube/config"
chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.kube"
