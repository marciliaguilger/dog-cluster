provider "aws" {
  region  = "us-east-1"
  profile = "pos"
}

# Referencie a VPC existente
data "aws_vpc" "existing_vpc" {
  id = "vpc-0a288c24930e9a742"
}

# Referencie as sub-redes existentes
data "aws_subnets" "existing_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }
}

resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "dog_development" {
  name     = "dog-eks-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.existing_subnets.ids
  }
}

resource "aws_iam_role" "node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_group_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "registry_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "dog_node_group" {
  cluster_name    = aws_eks_cluster.dog_development.name
  node_group_name = "dog-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = ["subnet-0c18fc34912b5cde3", "subnet-08bf99e4f496868fb"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.small"]
  capacity_type  = "SPOT"
}

data "aws_eks_cluster_auth" "dog_development" {
  name = aws_eks_cluster.dog_development.name
  depends_on = [aws_eks_cluster.dog_development]
}

provider "kubernetes" {
  host                   = aws_eks_cluster.dog_development.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.dog_development.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.dog_development.token
}

resource "kubernetes_service_account" "dog-service-account" {
  metadata {
    name      = "dog-service-account"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::764549915701:role/secrets-manager-role"
    }
  }
}