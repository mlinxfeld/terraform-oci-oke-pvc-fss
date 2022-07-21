output "cluster_instruction" {
value = <<EOT
1.  Open OCI Cloud Shell.

2.  Execute below command to setup OKE cluster access:

$ oci ce cluster create-kubeconfig --region ${var.region} --cluster-id ${oci_containerengine_cluster.FoggyKitchenOKECluster.id}

3.  Obtain the PVC created by the automation

$ kubectl get pvc  

4.  Obtain ${var.pod_name}1 POD description with attached PVC

$ kubectl describe pod ${var.pod_name}1

5.  Access the POD to check the status of the mount

$ kubectl exec -it  ${var.pod_name}1 -- mount | grep ocifss

EOT
}