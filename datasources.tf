data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid

  filter {
    name   = "is_home_region"
    values = [true]
  }
}

data "oci_containerengine_cluster_option" "FoggyKitchenOKEClusterOption" {
  cluster_option_id = "all"
}

data "oci_containerengine_node_pool_option" "FoggyKitchenOKEClusterNodePoolOption" {
  node_pool_option_id = "all"
}

# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  provider       = oci.targetregion
  compartment_id = var.tenancy_ocid
}

# Get the latest Oracle Linux image
data "oci_core_images" "InstanceImageOCID" {
  provider                 = oci.targetregion
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.shape

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

data "oci_core_services" "FoggyKitchenAllOCIServices" {
  provider       = oci.targetregion

  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_containerengine_node_pool" "FoggyKitchenOKENodePool" {
    node_pool_id = oci_containerengine_node_pool.FoggyKitchenOKENodePool.id
}

data "template_file" "pv_deployment" {

  template = "${file("${path.module}/templates/pv.template.yaml")}"
  vars     = {
      file_storage_export_path = var.file_storage_export_path
      mount_target_ip_address  = var.mount_target_ip_address
      file_system_id           = oci_file_storage_file_system.FoggyKitchenFilesystem.id
      pv_name                  = var.pv_name
      pv_size                  = var.pv_size
  }
}

data "template_file" "pvc_deployment" {

  template = "${file("${path.module}/templates/pvc.template.yaml")}"
  vars     = {
      pvc_name = var.pvc_name
      pvc_size = var.pvc_size
      pv_name  = var.pv_name
  }
}

data "template_file" "nginx_deployment" {
  count    = var.number_of_pods
  template = "${file("${path.module}/templates/nginx.template.yaml")}"
  vars     = {
      pvc_name = var.pvc_name
      pod_name = "${var.pod_name}${count.index+1}"
  }
}
