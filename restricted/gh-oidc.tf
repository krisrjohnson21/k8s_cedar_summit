## GitHub OIDC provider — lets GitHub Actions authenticate to AWS without long-lived keys
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_ecr_repository" "cedar_summit" {
  name = var.cluster_name
}

data "aws_eks_cluster" "cedar_summit" {
  name = var.cluster_name
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

## IAM role that GitHub Actions assumes via OIDC
data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:krisrjohnson21/k8s_cedar_summit:*"]
    }
  }
}

data "aws_iam_policy_document" "github_actions_permissions" {
  # ECR — push images
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [data.aws_ecr_repository.cedar_summit.arn]
  }

  # EKS — deploy to cluster
  statement {
    actions = [
      "eks:DescribeCluster",
    ]
    resources = [data.aws_eks_cluster.cedar_summit.arn]
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.cluster_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "${var.cluster_name}-github-actions"
  role   = aws_iam_role.github_actions.name
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}

output "github_actions_role_arn" {
  description = "ARN for GitHub Actions to assume via OIDC"
  value       = aws_iam_role.github_actions.arn
}

## EKS access entry — lets the GitHub Actions role interact with the cluster
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = data.aws_eks_cluster.cedar_summit.name
  principal_arn = aws_iam_role.github_actions.arn
}

resource "aws_eks_access_policy_association" "github_actions" {
  cluster_name  = data.aws_eks_cluster.cedar_summit.name
  principal_arn = aws_iam_role.github_actions.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions]
}
