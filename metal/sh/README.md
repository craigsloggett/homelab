# POSIX Shell Provisioning Script

To run these scripts on a remote host, use `ssh` as follows:

```sh
ssh root@remote-machine ARG1="arg1" ARG2="arg2" 'bash -s' < local_script.sh
```

These scripts are meant to be run in order on all nodes up until `4-kubeadm.sh`. Following this,
all nodes will be rebooted and the rest of the scripts must be run on the control plane nodes.

**TODO**: Research more on bare metal K8s network add-ons.
