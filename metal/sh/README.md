# Shell Provisioning Scripts

To run these scripts on a remote host, use `ssh` as follows:

```sh
ssh root@remote-machine ARG1="arg1" ARG2="arg2" 'bash -s' < local_script.sh
```

These scripts are meant to be run in order on all nodes up until `4-kubeadm.sh`. Following this,
all nodes will be rebooted and the rest of the scripts must be run on the control plane nodes.

## CRI-O

The CRI-O project packages for Debian such that you can install the container engine using `apt`. First we need to install the necessary dependencies to add an Apt repository to the system:

```shell
apt install curl gnupg apt-transport-https ca-certificates
```

We will be using the bundled `runc` to ensure the version of `cri-o` installed works with the version of `runc` installed. Since we're using the packaged version, there's no additional configuration required to make it work.

The container network plugins will be installed separately during the Kubernetes tooling setup and configuration.

To check the version of `cri-o` installed:

```shell
crio --version
```

## kubelet

### cgroup Driver

> The Container runtimes page explains that the `systemd` driver is recommended for kubeadm based setups instead of the `cgroupfs` driver, because kubeadm manages the kubelet as a systemd service.

> **Note:** In v1.22, if the user is not setting the cgroupDriver field under KubeletConfiguration, kubeadm will default it to systemd.

Since we are installing a version later than `v1.22`, we don't need to specify this configuration (as it is the default).

## Control Plane

The default Service CIDR is `10.96.0.0/12`
The default Pod CIDR is `10.32.0.0/12`

We would like to update the Pod CIDR to align with Flannel's defaults of `10.244.0.0/16`. And since this uses a `/16`, we might as well update the Service CIDR to match this.

We need to update the `criSocket` configuration to point to `unix:///var/run/crio/crio.sock` (instead of the default `containerd` configuration).

We have added the `kube-proxy` configuration to `kubeadm-config.yaml` in order to support MetalLB's required configuration later.

## Pod Network Add-on

The goal is to use the default Flannel configuration "as-is" so we don't have to vendor the configuration file. Ultimately, we want everything represented in the `cluster/` directory of the repository to be deployed and managed by Flux (which is installed after the network add-on).

To install this run the following command on one of the control plane nodes:

```shell
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

## Worker Nodes

Now it's time to join all of the worker nodes to the cluster. The `kubeadm init` command provided output for this, follow that to join the rest of the nodes.

## MetalLB

**TODO:** Move this to be deployed by flux.

The `kube-proxy` configuration has been updated to enable strict ARP by default as part of the kubeadm init configuration.

To install this run the following command on one of the control plane nodes:

```shell
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml
```
