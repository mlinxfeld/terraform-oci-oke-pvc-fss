resource "local_file" "pv_deployment" {
  content  = data.template_file.pv_deployment.rendered
  filename = "${path.module}/pv.yaml"
}

resource "local_file" "pvc_deployment" {
  content  = data.template_file.pvc_deployment.rendered
  filename = "${path.module}/pvc.yaml"
}

resource "local_file" "nginx_deployment" {
  count    = var.number_of_pods
  content  = data.template_file.nginx_deployment[count.index].rendered
  filename = "${path.module}/nginx${count.index+1}.yaml"
}

resource "null_resource" "deploy_oke_pv" {
  depends_on = [
  oci_containerengine_cluster.FoggyKitchenOKECluster, 
  oci_containerengine_node_pool.FoggyKitchenOKENodePool,
  local_file.pv_deployment]

  provisioner "local-exec" {
    command = "oci ce cluster create-kubeconfig --region ${var.region} --cluster-id ${oci_containerengine_cluster.FoggyKitchenOKECluster.id}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.pv_deployment.filename}"
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

}

resource "null_resource" "deploy_oke_pvc" {
  depends_on = [
  oci_containerengine_cluster.FoggyKitchenOKECluster, 
  oci_containerengine_node_pool.FoggyKitchenOKENodePool, 
  null_resource.deploy_oke_pv,
  local_file.pvc_deployment]

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.pvc_deployment.filename}"
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

}

resource "null_resource" "deploy_oke_label_nodes" {
  count = var.node_pool_size
  depends_on = [
  oci_containerengine_cluster.FoggyKitchenOKECluster, 
  oci_containerengine_node_pool.FoggyKitchenOKENodePool, 
  local_file.nginx_deployment,
  null_resource.deploy_oke_pvc]

  provisioner "local-exec" {
    command = "kubectl label node ${oci_containerengine_node_pool.FoggyKitchenOKENodePool.nodes[count.index].private_ip} nodeName=node${count.index+1}"
  }  

}

resource "null_resource" "deploy_oke_nginx" {
  count = var.number_of_pods
  depends_on = [
  oci_containerengine_cluster.FoggyKitchenOKECluster, 
  oci_containerengine_node_pool.FoggyKitchenOKENodePool, 
  local_file.nginx_deployment,
  null_resource.deploy_oke_label_nodes]

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.nginx_deployment[count.index].filename}"
  }

  provisioner "local-exec" {
    command = "sleep 120"
  }

  provisioner "local-exec" {
    command = "kubectl get pod ${var.pod_name}${count.index+1}"
  }

  provisioner "local-exec" {
    command = "kubectl describe pod ${var.pod_name}${count.index+1}"
  }
}