#!/bin/sh
#
# k8s-ipvs.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

# Enable IPVS
if ! command -v ipvsadm; then
	apt-get install -y ipvsadm ipset conntrack
fi

if ! grep -q 'ip_vs' /etc/modules-load.d/modules.conf; then
	cat >> /etc/modules-load.d/modules.conf <<- 'EOF'
	ip_vs
	ip_vs_rr
	ip_vs_wrr
	ip_vs_sh
	nf_conntrack
	EOF
fi

# Manually Load Kernel Modules
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack
