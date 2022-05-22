#!/bin/sh
#
# config-kernel.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

# Enable Overlay Networking
if ! grep -q 'overlay' /etc/modules-load.d/modules.conf; then
	printf '%s\n' "overlay" >> /etc/modules-load.d/modules.conf
fi

# Enable Bridge Networking
if ! grep -q 'br_netfilter' /etc/modules-load.d/modules.conf; then
	printf '%s\n' "br_netfilter" >> /etc/modules-load.d/modules.conf
fi

# Manually Load Kernel Modules
modprobe overlay
modprobe br_netfilter

# Enable iptables Filtering on the Bridge Network
if ! grep -q 'net.bridge.bridge-nf-call-iptables' /etc/sysctl.d/local.conf; then
	cat >> /etc/sysctl.d/local.conf <<- 'EOF'
	net.bridge.bridge-nf-call-iptables = 1
	net.bridge.bridge-nf-call-ip6tables = 1
	EOF
fi

# Enable IP Forwarding
if ! grep -q 'net.ipv4.ip_forward' /etc/sysctl.d/local.conf; then
	printf '%s\n' "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/local.conf
fi

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

# Reload Kernel Variables
sysctl --system
