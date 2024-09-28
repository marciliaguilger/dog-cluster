## Security Group para o ALB
#resource "aws_security_group" "alb_sg" {
#  name        = "alb-sg"
#  description = "Security group for ALB"
#  vpc_id      = data.aws_vpc.existing_vpc.id
#  ingress {
#    from_port   = 80
#    to_port     = 80
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}
## Application Load Balancer
#resource "aws_lb" "my_alb" {
#  name               = "my-alb"
#  internal           = false
#8:36
#load_balancer_type = "application"
#  security_groups    = [aws_security_group.alb_sg.id]
#  subnets            = data.aws_subnets.private_subnets.ids
#  enable_deletion_protection = false
#}
## Target Group
#resource "aws_lb_target_group" "my_target_group" {
#  name     = "my-target-group"
#  port     = 80
#  protocol = "HTTP"
#  vpc_id   = data.aws_vpc.existing_vpc.id
#  health_check {
#    path                = "/health"
#    interval            = 30
#    timeout             = 5
#    healthy_threshold   = 5
#    unhealthy_threshold = 2
#    matcher             = "200-299"
#  }
#}
## Listener do ALB
#resource "aws_lb_listener" "http" {
#  load_balancer_arn = aws_lb.my_alb.arn
#  port              = "80"
#  protocol          = "HTTP"
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.my_target_group.arn
#  }
#}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}


data "aws_eks_cluster" "eks" {
  name = "dog-eks-cluster"
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.eks.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

resource "aws_iam_role" "alb_ingress_controller" {
  name = "alb-ingress-controller"

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

resource "aws_iam_role_policy_attachment" "alb_ingress_controller" {
  role       = aws_iam_role.alb_ingress_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "alb_ingress_controller_vpc" {
  role       = aws_iam_role.alb_ingress_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "kubernetes_service_account" "alb_ingress" {
  metadata {
    name      = "alb-ingress-controller"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_ingress_controller.arn
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "default"

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.eks.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.alb_ingress.metadata[0].name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = data.aws_eks_cluster.eks.vpc_config[0].vpc_id
  }
}