#!/bin/sh
#
# k8s-network-add-on.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${FLANNEL_VERSION:=0.17.0}"

# Download the flanneld Binary
if [ ! -f /opt/bin/flanneld ]; then
	curl -LO "https://github.com/flannel-io/flannel/releases/download/v${FLANNEL_VERSION}/flanneld-arm64"
	mkdir -p /opt/bin
	mv flanneld-arm64 /opt/bin/flanneld
	chmod +x /opt/bin/flanneld
fi
