data "aws_caller_identity" "me" {}

# 1) GitHub OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    # GitHub OIDC root CA thumbprint (current)
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}


# 2) IAM role assumed by GitHub Actions
resource "aws_iam_role" "gha_tf_role" {
  name = "gha-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          # Only this repo’s workflows (default branch or env) can assume
          "token.actions.githubusercontent.com:sub" = [
            "repo:arseny010/ci-cd-project:ref:refs/heads/main",
            "repo:arseny010/ci-cd-project:pull_request"
          ]
        }
      }
    }]
  })
}

# 3) Minimal policy for Terraform state + common AWS ops
data "aws_iam_policy_document" "gha_tf_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::arseny-tf-state-<your-suffix>",
      "arn:aws:s3:::arseny-tf-state-<your-suffix>/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem","dynamodb:PutItem","dynamodb:DeleteItem","dynamodb:UpdateItem"
    ]
    resources = [
      "arn:aws:dynamodb:us-east-2:${data.aws_caller_identity.me.account_id}:table/terraform-locks"
    ]
  }

  # Allow creating common demo resources; tighten later for prod
  statement {
    effect = "Allow"
    actions = [
      "s3:*", "ec2:*", "iam:PassRole", "cloudwatch:*", "logs:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gha_tf" {
  name   = "gha-terraform-policy"
  policy = data.aws_iam_policy_document.gha_tf_policy.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.gha_tf_role.name
  policy_arn = aws_iam_policy.gha_tf.arn
}

output "gha_role_arn" { value = aws_iam_role.gha_tf_role.arn }