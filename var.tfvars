### Libvirt Details
libvirt_uri                        = "qemu+tcp://localhost/system"
host_address                       = ""
images_path                        = "/home/libvirt/openshift-images"

### OpenShift Cluster Details

bastion                            = { memory = 8192,  vcpu = 2 }
bootstrap                          = { memory = 8192,  vcpu = 4, count = 1 }
master                             = { memory = 16384, vcpu = 4, count = 3 }
worker                             = { memory = 16384, vcpu = 4, count = 2 }

bastion_image                      = "<url-or-path-to-rhel-qcow2>"
rhcos_image                        = "<url-or-path-to-rhcos-qcow2>"

rhel_username                      = "root"
rhel_password                      = "<password>"
public_key_file                    = "data/id_rsa.pub"
private_key_file                   = "data/id_rsa"

rhel_subscription_username         = ""
rhel_subscription_password         = ""
rhel_subscription_org              = ""
rhel_subscription_activationkey    = ""

### OpenShift Installation Details

openshift_install_tarball          = "https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp-dev-preview/latest/openshift-install-linux.tar.gz"
openshift_client_tarball           = "https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp-dev-preview/latest/openshift-client-linux.tar.gz"
pull_secret_file                   = "data/pull-secret.txt"
cluster_domain                     = "ibm.com"
cluster_id_prefix                  = "test-ocp" # Set it to empty if just want to use cluster_id without prefix
cluster_id                         = ""         # It will use random generated id with cluster_id_prefix if this is not set


### Misc Customizations

#cpu_mode                          = ""
#network_cidr                      = ""

#enable_local_registry             = false  #Set to true to enable usage of the local registry for restricted network install.
#local_registry_image              = "docker.io/ibmcom/registry-ppc64le:2.6.2.5"
#ocp_release_tag                   = "4.6.1-ppc64le"
#release_image_override            = ""


#helpernode_tag                    = ""
#install_playbook_tag              = ""

#installer_log_level               = "info"
#ansible_extra_options             = "-v"
#ansible_repo_name                 = "ansible-2.9-for-rhel-8-ppc64le-rpms"
#dns_forwarders                    = "1.1.1.1; 9.9.9.9"
#rhcos_kernel_options              = []
#chrony_config                     = true
#chrony_config_servers             = [ {server = "0.centos.pool.ntp.org", options = "iburst"}, {server = "1.centos.pool.ntp.org", options = "iburst"} ]


#storage_type                      = "nfs"
#volume_size                       = "300" # Value in GB

#upgrade_version                   = ""
#upgrade_channel                   = ""  #(stable-4.x, fast-4.x, candidate-4.x) eg. stable-4.5
#upgrade_pause_time                = "90"
#upgrade_delay_time                = "600"



