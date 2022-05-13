#!/bin/sh
#
# k8s-nodes.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${CONTROL_PLANE_ENDPOINT:=192.168.1.110}"

# Initialize the Nodes
kubeadm join "${CONTROL_PLANE_ENDPOINT}:6443" --token xxxxxxxxxx --discovery-token-ca-cert-hash sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaa
