# How to use var.tfvars

- [How to use var.tfvars](#how-to-use-vartfvars)
  - [Introduction](#introduction)
    - [Libvirt Details](#libvirt-details)
    - [OpenShift Cluster Details](#openshift-cluster-details)
    - [OpenShift Installation Details](#openshift-installation-details)
    - [Misc Customizations](#misc-customizations)


## Introduction

This guide gives an overview of the various terraform variables that are used for the deployment.
The default values are set in [variables.tf](../variables.tf)

### Libvirt Details

These set of variables specify the Libvirt details.

```
libvirt_uri                        = "qemu+tcp://localhost/system"
host_address                       = ""
images_path                        = "/home/libvirt/openshift-images"
```

### OpenShift Cluster Details

These set of variables specify the cluster capacity.

```
bastion                            = { memory = 8192,  vcpu = 2 }
bootstrap                          = { memory = 8192,  vcpu = 4, count = 1 }
master                             = { memory = 16384, vcpu = 4, count = 3 }
worker                             = { memory = 16384, vcpu = 4, count = 2 }
```

You can optionally set worker `count` value to 0 in which case all the cluster pods will be running on the master/supervisor nodes.
Ensure you use proper sizing for master/supervisor nodes to avoid resource starvation for containers.

These set of variables specify the RHEL and RHCOS boot image location. Ensure that you use the correct RHCOS image specific to the pre-release version.
```
bastion_image                      = "<url-or-path-to-rhel-qcow2>"
rhcos_image                        = "<url-or-path-to-rhcos-qcow2>"
```

These set of variables specify the username, password and the SSH key to be used for accessing the bastion node.
```
rhel_username                      = "root"
rhel_password                      = "<password>"
public_key_file                    = "data/id_rsa.pub"
private_key_file                   = "data/id_rsa"
```
Please note that only OpenSSH formatted keys are supported. Refer to the following links for instructions on creating SSH key based on your platform.
- Windows 10 - https://phoenixnap.com/kb/generate-ssh-key-windows-10
- Mac OSX - https://www.techrepublic.com/article/how-to-generate-ssh-keys-on-macos-mojave/
- Linux - https://www.siteground.com/kb/generate_ssh_key_in_linux/

Create the SSH key-pair and keep it under the `data` directory

These set of variables specify the RHEL subscription details.
This is sensitive data, and if you don't want to save it on disk, use environment variables `RHEL_SUBS_USERNAME` and `RHEL_SUBS_PASSWORD` and
pass them to `terraform apply` command as shown in the [Quickstart guide](./quickstart.md#setup-terraform-variables).

```
rhel_subscription_username         = "user@test.com"
rhel_subscription_password         = "mypassword"
```
If you have an org wide activation key, then use the following variables
```
rhel_subscription_org              = ""
rhel_subscription_activationkey    = ""
```

### OpenShift Installation Details

These variables specify the URL for the OpenShift installer and client binaries.
Change the URL to the specific pre-release version that you want to install on PowerVS.
Reference link - `https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp-dev-preview`
```
openshift_install_tarball          = "https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp-dev-preview/latest/openshift-install-linux.tar.gz"
openshift_client_tarball           = "https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp-dev-preview/latest/openshift-client-linux.tar.gz"
```

This variable specifies the OpenShift pull secret. This is available from the following link -  https://cloud.redhat.com/openshift/install/power/user-provisioned
Download the secret and copy it to `data/pull-secret.txt`.
```
pull_secret_file                   = "data/pull-secret.txt"
```

These variables specifies the OpenShift cluster domain details.
Edit it as per your requirements.
```
cluster_domain                     = "ibm.com"
cluster_id_prefix                  = "test-ocp"
cluster_id                         = ""
```
The `cluster_id_prefix` should not be more than 8 characters. Nodes are pre-fixed with this value.
Default value is `test-ocp`
If `cluster_id_prefix` is not set, the `cluster_id` will be used only without prefix.

A random value will be used for `cluster_id` if not set.
The total length of `cluster_id_prefix`.`cluster_id` should not exceed 14 characters.

### Misc Customizations

These variables provides miscellaneous customizations. For common usage scenarios these are not required and should be left unchanged.

The following variable is used to specify the Libvirt VM CPU mode. For example custom, host-passthrough, host-model.
```
cpu_mode                           = ""
```

The following variable is used to define the network subnet for the OCP cluster. Default is set to '192.168.27.0/24'.
```
network_cidr                       = ""
```

The following variables can be used for disconnected install by using a local mirror registry on the bastion node.

```
enable_local_registry              = false  #Set to true to enable usage of local registry for restricted network install.
local_registry_image               = "docker.io/ibmcom/registry-ppc64le:2.6.2.5"
ocp_release_tag                    = "4.4.9-ppc64le"
```

This variable can be used for trying out custom OpenShift install image for development use.
```
release_image_override             = ""
```

These variables specify the ansible playbooks that are used for OpenShift install and post-install customizations.
```
helpernode_tag                     = "5eab3db53976bb16be582f2edc2de02f7510050d"
install_playbook_tag               = "02a598faa332aa2c3d53e8edd0e840440ff74bd5"
```

GThese variables can be used when debugging ansible playbooks
```
installer_log_level                = "info"
ansible_extra_options              = "-v"
```

This variable specifies the external DNS servers to forward DNS queries that cannot be resolved locally.
```
dns_forwarders                     = "1.1.1.1; 9.9.9.9"
```

List of [kernel arguments](https://docs.openshift.com/container-platform/4.6/nodes/nodes/nodes-nodes-working.html#nodes-nodes-kernel-arguments_nodes-nodes-working) for the cluster nodes.
Note that this will be applied after the cluster is installed and all the nodes are in `Ready` status.
```
rhcos_kernel_options        = []
```
- Example 1
  ```
  rhcos_kernel_options      = ["slub_max_order=0","loglevel=7"]
  ```

These are NTP specific variables that are used for time-synchronization in the OpenShift cluster.
```
chrony_config                      = true
chrony_config_servers              = [ {server = "0.centos.pool.ntp.org", options = "iburst"}, {server = "1.centos.pool.ntp.org", options = "iburst"} ]
```

These variables specify details about NFS storage that is setup by default on the bastion server.

```
storage_type                       = "nfs"
volume_size                        = "300" # Value in GB
```

The following variables are specific to upgrading an existing installation.

```
upgrade_version                    = ""
upgrade_channel                    = ""  #(stable-4.x, fast-4.x, candidate-4.x) eg. stable-4.5
upgrade_pause_time                 = "90"
upgrade_delay_time                 = "600"
```
