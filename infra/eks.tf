module "cedar_summit_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Allow public access to the K8s API so you can run kubectl from your laptop
  endpoint_public_access = true

  # Managed node group — AWS handles the EC2 lifecycle
  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      min_size       = 1
      max_size       = 3
      desired_size   = var.node_desired_count
    }
  }

  # Give your IAM user cluster admin access
  enable_cluster_creator_admin_permissions = true

  # Add-ons
  addons = {
    vpc-cni = {
      before_compute = true
    }
    coredns    = {}
    kube-proxy = {}
  }
}
