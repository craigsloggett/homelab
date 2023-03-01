# Kubernetes Bare Metal Provisioning Script

To run this on a remote host:
```sh
ssh root@remote-machine ARG1="arg1" ARG2="arg2" 'bash -s' < local_script.sh
```

## Base OS

Run all of the scripts to prep the Base OS.

## Control Node

Run the 10-XXX script to bootstrap the control node. When it is done, it will print out a command you can run on all of the worker nodes.

## Worker Nodes

Run the `kubeadm join` specified by the controller node bootstrap process.

## Verify

Check the status of the cluster with: `kubectl get nodes`
