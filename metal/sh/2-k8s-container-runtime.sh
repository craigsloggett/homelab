#!/bin/sh
#
# k8s-container-runtime.sh

# Globally enable exit-on-error and require variables to be set.
set -o errexit
set -o nounset

: "${CRIO_OS:=Debian_11}"
: "${CRIO_VERSION:=1.23}"

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

# Install Dependencies
apt-get install -y \
	curl \
	gnupg \
	apt-transport-https \
	ca-certificates

libcontainers_repo_url="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable"

# Download the Open Container Initiative Repository Key Ring
libcontainers_keyring="/usr/share/keyrings/libcontainers-archive-keyring.gpg"

rm -f "${libcontainers_keyring}"  # Remove existing to allow updates.
curl -L "${libcontainers_repo_url}/${CRIO_OS}/Release.key" \
	| gpg --dearmor -o "${libcontainers_keyring}"

# Add the Open Container Initiative Package Sources List
cat > /etc/apt/sources.list.d/libcontainers-sources.list <<- EOF
deb [signed-by=${libcontainers_keyring}] ${libcontainers_repo_url}/${CRIO_OS}/ /
EOF

# Download the Container Runtime Interface Repository Key Ring
crio_keyring="/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg"

rm -f "${crio_keyring}"  # Remove existing to allow updates.
curl -L "${libcontainers_repo_url}:/cri-o:/${CRIO_VERSION}/${CRIO_OS}/Release.key" \
	| gpg --dearmor -o "${crio_keyring}"

# Add the Container Runtime Interface Package Sources List
cat > /etc/apt/sources.list.d/cri-o-sources.list <<- EOF
deb [signed-by=${crio_keyring}] ${libcontainers_repo_url}:/cri-o:/${CRIO_VERSION}/${CRIO_OS}/ /
EOF

# Update the Apt Cache
apt-get update

# Upgrade the System
apt-get -y upgrade
apt-get -y autoremove

# Install the Container Runtime Interface
apt-get -y install cri-o cri-o-runc

# Enable and Start the Container Runtime Interface
systemctl enable crio
systemctl start crio
