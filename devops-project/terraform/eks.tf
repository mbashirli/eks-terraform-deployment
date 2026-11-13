resource "aws_security_group" "eks" {
  name   = "eks-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    description     = "HTTPS from bastion host"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "1"
  }
  tags = {
    Terraform = "true"
    Name      = "eks-sg"
  }
}

module "eks" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "21.29.0"
  name               = "eks-cluster-dev"
  kubernetes_version = "1.35"
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  endpoint_public_access                   = false
  enable_cluster_creator_admin_permissions = true
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  additional_security_group_ids            = [aws_security_group.eks.id]
  eks_managed_node_groups = {
    eks-group = {
      instance_type = ["c7i-flex.large"]
      min_size      = 2
      max_size      = 10
      desired_size  = 2
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
    Name        = "eks-cluster-dev"
  }
}