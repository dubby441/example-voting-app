# GitHub Actions OIDC, ECR repositories, and EKS access for the capstone.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_ecr_repository" "voting_app" {
  for_each             = toset(["vote", "result", "worker"])
  name                 = "voting-${each.key}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
  force_delete = true
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:dubby441/example-voting-app:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-voting-capstone"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid       = "ECRLogin"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid    = "PushVotingImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload",
      "ecr:DescribeImages", "ecr:DescribeRepositories",
      "ecr:InitiateLayerUpload", "ecr:ListImages", "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [for repo in aws_ecr_repository.voting_app : repo.arn]
  }
  statement {
    sid       = "DescribeVotingCluster"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:aws:eks:eu-north-1:639175159338:cluster/voting-capstone"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "voting-capstone-ci"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}

resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = "voting-capstone"
  principal_arn = aws_iam_role.github_actions.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = "voting-capstone"
  principal_arn = aws_iam_role.github_actions.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
  depends_on = [aws_eks_access_entry.github_actions]
}

output "github_actions_role_arn" {
  description = "Set this as the GitHub Actions repository variable AWS_ROLE_ARN."
  value       = aws_iam_role.github_actions.arn
}
output "ecr_vote_repository_url" { value = aws_ecr_repository.voting_app["vote"].repository_url }
output "ecr_result_repository_url" { value = aws_ecr_repository.voting_app["result"].repository_url }
output "ecr_worker_repository_url" { value = aws_ecr_repository.voting_app["worker"].repository_url }
