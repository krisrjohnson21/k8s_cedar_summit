output "cluster_name" {
  description = "EKS cluster name"
  value       = module.cedar_summit_eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.cedar_summit_eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL for pushing images"
  value       = aws_ecr_repository.cedar_summit.repository_url
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.cedar_summit_eks.cluster_name}"
}
