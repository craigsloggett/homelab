#!/bin/sh
#
# k8s-network-add-on.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

export KUBECONFIG=/etc/kubernetes/admin.conf

# Download and Install the Cilium CLI
if ! command -v cilium; then
	curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-arm64.tar.gz
	sudo tar xzvfC cilium-linux-arm64.tar.gz /usr/local/bin
	rm cilium-linux-arm64.tar.gz
fi

# Install Cilium
cilium install
