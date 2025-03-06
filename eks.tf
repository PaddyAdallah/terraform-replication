
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>20.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.32"
  
  authentication_mode                         = "API_AND_CONFIG_MAP"
  
  # Only applicable at cluster creation
  # bootstrap_cluster_creator_admin_permissions = true

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  
  # Gives Terraform identity admin access to cluster which will
  # allow deploying resources (Karpenter) into the cluster
  enable_cluster_creator_admin_permissions = true
  
  access_entries = {
    # One access entry with a policy associated
    example = {
      principal_arn = "arn:aws:iam::654654529400:user/lens"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
        }
        }
        }
  
  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }
   cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    karpenter = {
      name = "karpenter"

      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 3
      desired_size = 2
      
      labels = {
      # Used to ensure Karpenter runs on nodes that it does not manage
      "karpenter.sh/controller" = "true"
      }
      
      taints = {
         # This Taint aims to keep just EKS Addons and Karpenter running on this MNG
         # The pods that do not tolerate this taint should run on nodes created by Karpenter
        addons = {
          key = "CriticalAddonsOnly"
          value = "true"
          effect = "NO_SCHEDULE"
        }
      }
      tags = {
        auto-delete = "no"
      }
    }
  }
  create_node_security_group = false

}

# From 
# https://github.com/akw-devsecops/terraform-aws-eks/tree/v4.1.0/modules/aws-load-balancer-controller
module "aws_load_balancer_controller_irsa_role" {

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "aws-load-balancer-controller"
  
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    sts = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}
