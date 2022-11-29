data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid

  filter {
    name   = "is_home_region"
    values = [true]
  }
}

data "oci_containerengine_cluster_option" "FoggyKitchenOKEClusterOption" {
  provider          = oci.targetregion
  cluster_option_id = "all"
}

data "oci_containerengine_node_pool_option" "FoggyKitchenOKEClusterNodePoolOption" {
  provider            = oci.targetregion
  node_pool_option_id = "all"
}

# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  provider       = oci.targetregion
  compartment_id = var.tenancy_ocid
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
    provider     = oci.targetregion
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
      pvc_name                = var.pvc_name
      pod_name                = "${var.pod_name}"
      number_of_pods_replicas = var.number_of_pods_replicas
      node_index              = "${(count.index % 3) + 1}"
      is_arm_node_shape       = local.is_arm_node_shape
  }
}

data "template_file" "service_deployment" {

  template = "${file("${path.module}/templates/service.template.yaml")}"
  vars     = {
      lb_shape          = var.lb_shape
      flex_lb_min_shape = var.flex_lb_min_shape 
      flex_lb_max_shape = var.flex_lb_max_shape  
      lb_listener_port  = var.lb_listener_port
      lb_nsg            = var.lb_nsg
      lb_nsg_id         = var.lb_nsg ? oci_core_network_security_group.FoggyKitchenOKELBSecurityGroup[0].id : ""
  }
}