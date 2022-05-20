#!/bin/sh
#
# k8s-network-add-on.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${FLANNEL_VERSION:=0.17.0}"
: "${CONTROL_IP:=192.168.1.110}"
: "${NODE_0_IP:=192.168.1.120}"
: "${NODE_1_IP:=192.168.1.121}"
: "${NODE_2_IP:=192.168.1.122}"

# Download the flanneld Binary
if [ ! -f /opt/bin/flanneld ]; then
	curl -LO "https://github.com/flannel-io/flannel/releases/download/v${FLANNEL_VERSION}/flanneld-arm64"
	mkdir -p /opt/bin
	mv flanneld-arm64 /opt/bin/flanneld
	chmod +x /opt/bin/flanneld
fi

# Update the Hosts File with Cluster IPs
hostname="$(hostname)"

cat > /etc/hosts <<- EOF
127.0.0.1	${hostname}.localdomain ${hostname}
::1		${hostname}.localdomain ${hostname} ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

${CONTROL_IP}	controller-0
${NODE_0_IP}	node-0
${NODE_1_IP}	node-1
${NODE_2_IP}	node-2
EOF

printf '%s\n' "It is now a good time to reboot all of the nodes."
