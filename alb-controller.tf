# terraform/helm-load-balancer-controller.tf

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "~>1.5.0"
  

  set {
    name  = "replicaCount"
    value = 2
  }

  set {
  name = "region"
  value = "eu-west-1"
  }
  
  set{
  name = "vpcId"
  value =  "vpc-080a8f168cf08ac7d"
  }
  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }
}
