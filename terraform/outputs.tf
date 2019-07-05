locals {
  /* worker nodesをクラスターに参加させるConfigMap
以下で取得可能:
$ terraform output config_map_aws_auth
[参考]
https://learn.hashicorp.com/terraform/aws/eks-intro#required-kubernetes-configuration-to-join-worker-nodes
*/
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.sample-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

/* kubectlをクラスターに向ける設定
以下で取得可能:
$ terraform output kubeconfig

このconfigを使う前に以下を打つこと:
```
`$ eks get-token --cluster-name terraform-eks-sample > /root/.kube/token
```

[参考]
https://learn.hashicorp.com/terraform/aws/eks-intro#configuring-kubectl-for-eks
https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins
https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html
*/
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.sample.endpoint}
    certificate-authority-data: ${aws_eks_cluster.sample.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: cat
      args:
        - /root/.kube/token
KUBECONFIG
}

output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}
