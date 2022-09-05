output "cluster_instruction" {
value = <<EOT
1.  Open OCI Cloud Shell.

2.  Execute below command to setup OKE cluster access:

$ oci ce cluster create-kubeconfig --region ${var.region} --cluster-id ${oci_containerengine_cluster.FoggyKitchenOKECluster.id}

3.  Obtain the PVC created by the automation

$ kubectl get pvc  

4.  Obtain PODs description with attached PVC

$ kubectl get pods 

5.  Pick up the first POD and check the status of the mount

$ kubectl exec -it <pod_taken_from_point4> -- mount | grep ocifss

6.  Get services

$ kubectl get services

EOT
}
