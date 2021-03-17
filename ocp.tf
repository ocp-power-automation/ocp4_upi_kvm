################################################################
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2020
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################

provider "libvirt" {
    uri = var.libvirt_uri
}
resource "random_id" "label" {
    count = var.cluster_id == "" ? 1 : 0
    byte_length = "2" # Since we use the hex, the word lenght would double
    prefix = "${var.cluster_id_prefix}-"
}

resource "random_id" "b" {
    byte_length = "3"
}
resource "random_id" "m" {
    count       = var.master["count"]
    byte_length = "3"
}
resource "random_id" "w" {
    count       = var.worker["count"]
    byte_length = "3"
}

locals {
    # Generates cluster_id as combination of cluster_id_prefix + (random_id or user-defined cluster_id)
    cluster_id  = var.cluster_id == "" ? random_id.label[0].hex : (var.cluster_id_prefix == "" ? var.cluster_id : "${var.cluster_id_prefix}-${var.cluster_id}")

    bootstrap = {
        ip      = cidrhost(var.network_cidr, 3)
        mac     = format(
                    "52:54:00:%s:%s:%s",
                    substr(random_id.b.hex,0,2),
                    substr(random_id.b.hex,2,2),
                    substr(random_id.b.hex,4,2)
                )
    }
    first_master_hostnum    = 4
    first_worker_hostnum    = 21
}

resource "null_resource" "master_info" {
    count       = var.master["count"]
    triggers    = {
        ip      = cidrhost(var.network_cidr, local.first_master_hostnum + count.index)
        mac     =  format(
                    "52:54:00:%s:%s:%s",
                    substr(random_id.m[count.index].hex,0,2),
                    substr(random_id.m[count.index].hex,2,2),
                    substr(random_id.m[count.index].hex,4,2)
                )
    }
}
resource "null_resource" "worker_info" {
    count       = var.worker["count"]
    triggers    = {
        ip      = cidrhost(var.network_cidr, local.first_worker_hostnum + count.index)
        mac     = format(
                    "52:54:00:%s:%s:%s",
                    substr(random_id.w[count.index].hex,0,2),
                    substr(random_id.w[count.index].hex,2,2),
                    substr(random_id.w[count.index].hex,4,2)
                )
    }
}


module "prepare" {
    source                          = "./modules/1_prepare"

    cluster_domain                  = var.cluster_domain
    cluster_id                      = local.cluster_id
    bastion                         = var.bastion
    cpu_mode                        = var.cpu_mode
    bastion_image                   = var.bastion_image
    rhel_username                   = var.rhel_username
    rhel_password                   = var.rhel_password
    private_key                     = local.private_key
    public_key                      = local.public_key
    ssh_agent                       = var.ssh_agent
    host_address                    = var.host_address
    network_cidr                    = var.network_cidr
    images_path                     = var.images_path
    rhel_subscription_username      = var.rhel_subscription_username
    rhel_subscription_password      = var.rhel_subscription_password
    rhel_subscription_org           = var.rhel_subscription_org
    rhel_subscription_activationkey = var.rhel_subscription_activationkey
    ansible_repo_name               = var.ansible_repo_name
    storage_type                    = var.storage_type
    volume_size                     = var.volume_size
}

module "helpernode" {
    source                          = "./modules/3_helpernode"

    cluster_domain                  = var.cluster_domain
    cluster_id                      = local.cluster_id
    dns_forwarders                  = var.dns_forwarders
    chrony_config                   = var.chrony_config
    chrony_config_servers           = var.chrony_config_servers
    gateway_ip                      = cidrhost(var.network_cidr,1)
    cidr                            = var.network_cidr
    allocation_pools                = [{"start": cidrhost(var.network_cidr,3), "end": cidrhost(var.network_cidr,-2)}]
    bastion_ip                      = module.prepare.bastion_ip
    rhel_username                   = var.rhel_username
    private_key                     = local.private_key
    ssh_agent                       = var.ssh_agent
    jump_host                       = var.host_address
    bootstrap_ip                    = local.bootstrap.ip
    master_ips                      = null_resource.master_info.*.triggers.ip
    worker_ips                      = null_resource.worker_info.*.triggers.ip
    bootstrap_mac                   = local.bootstrap.mac
    master_macs                     = null_resource.master_info.*.triggers.mac
    worker_macs                     = null_resource.worker_info.*.triggers.mac
    helpernode_tag                  = var.helpernode_tag
    openshift_install_tarball       = var.openshift_install_tarball
    openshift_client_tarball        = var.openshift_client_tarball
    enable_local_registry           = var.enable_local_registry
    local_registry_image            = var.local_registry_image
    ocp_release_tag                 = var.ocp_release_tag
    ansible_extra_options           = var.ansible_extra_options
    pull_secret                     = file(coalesce(var.pull_secret_file, "/dev/null"))
}

module "nodes" {
    depends_on                      = [module.prepare]
    source                          = "./modules/4_nodes"

    bastion_ip                      = module.prepare.bastion_ip
    cluster_domain                  = var.cluster_domain
    cluster_id                      = local.cluster_id
    bootstrap                       = var.bootstrap
    master                          = var.master
    worker                          = var.worker
    bootstrap_mac                   = local.bootstrap.mac
    master_macs                     = null_resource.master_info.*.triggers.mac
    worker_macs                     = null_resource.worker_info.*.triggers.mac
    cpu_mode                        = var.cpu_mode
    rhcos_image                     = var.rhcos_image
    storage_pool_name               = module.prepare.storage_pool_name
    network_cidr                    = var.network_cidr
    network_id                      = module.prepare.network_id
}

module "install" {
    depends_on                      = [module.helpernode, module.nodes]
    source                          = "./modules/5_install"

    cluster_domain                  = var.cluster_domain
    cluster_id                      = local.cluster_id
    bastion_ip                      = module.prepare.bastion_ip
    rhel_username                   = var.rhel_username
    private_key                     = local.private_key
    ssh_agent                       = var.ssh_agent
    jump_host                       = var.host_address
    chrony_config                   = var.chrony_config
    chrony_config_servers           = var.chrony_config_servers
    bootstrap_ip                    = local.bootstrap.ip
    master_ips                      = null_resource.master_info.*.triggers.ip
    worker_ips                      = null_resource.worker_info.*.triggers.ip
    public_key                      = local.public_key
    pull_secret                     = file(coalesce(var.pull_secret_file, "/dev/null"))
    storage_type                    = var.storage_type
    release_image_override          = var.release_image_override
    enable_local_registry           = var.enable_local_registry
    local_registry_image            = var.local_registry_image
    ocp_release_tag                 = var.ocp_release_tag
    install_playbook_tag            = var.install_playbook_tag
    log_level                       = var.installer_log_level
    ansible_extra_options           = var.ansible_extra_options
    rhcos_kernel_options            = var.rhcos_kernel_options
    upgrade_version                 = var.upgrade_version
    upgrade_channel                 = var.upgrade_channel
    upgrade_pause_time              = var.upgrade_pause_time
    upgrade_delay_time              = var.upgrade_delay_time
}
