provider "aws" {
  region  = "us-east-1"
  profile = "pos"
} 
 
resource "aws_iam_role" "secrets_manager_role" {
    name = "secrets-manager-role"
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            Service = "eks.amazonaws.com"
          }
          Action = "sts:AssumeRole"
        },
      ]
    })
  }
  resource "aws_iam_policy" "secrets_manager_policy" {
    name = "secrets-manager-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Resource = [
            "arn:aws:secretsmanager:us-east-1:764549915701:secret:rds/postgres/dog-restaurant/credentials-veZLOS"
          ]
        },
      ]
    })
  }
  resource "aws_iam_role_policy_attachment" "secrets_manager_role_policy" {
  role       = aws_iam_role.secrets_manager_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

