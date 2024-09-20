provider "aws" {
  region  = "us-east-1"
  profile = "pos"
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
    subnet_ids = ["subnet-0f7929d1b271ee353", "subnet-0e181418367a35ba8", "subnet-0814a612113aa40ec", "subnet-0133e56396d41f222"]
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSCNIPolicy"
}

resource "aws_iam_role_policy_attachment" "registry_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "dog_node_group" {
  cluster_name    = aws_eks_cluster.dog_development.name
  node_group_name = "dog-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = ["subnet-0f7929d1b271ee353", "subnet-0e181418367a35ba8", "subnet-0814a612113aa40ec", "subnet-0133e56396d41f222"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.small"]
  capacity_type  = "SPOT"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.dog_development.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.dog_development.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.dog_development.token
}

data "aws_eks_cluster_auth" "dog_development" {
  name = aws_eks_cluster.dog_development.name
}