resource "aws_vpc" "cnel_vpc" {
  cidr_block = var.cidr_block

  tags = var.tags
}


resource "aws_subnet" "cnel_public_subnet_one" {
  vpc_id     = aws_vpc.cnel_vpc.id
  cidr_block = var.cnel_public_subnet_one_cidr_block
  availability_zone = var.az_1

  tags = var.tags
}


resource "aws_subnet" "cnel_private_subnet_two" {
  vpc_id     = aws_vpc.cnel_vpc.id
  cidr_block = var.cnel_private_subnet_two_cidr_block
  availability_zone = var.az_1

  tags = var.tags
}


resource "aws_subnet" "cnel_public_subnet_three" {
  vpc_id     = aws_vpc.cnel_vpc.id
  cidr_block = var.cnel_public_subnet_three_cidr_block
  availability_zone = var.az_2

  tags = var.tags
}


resource "aws_subnet" "cnel_private_subnet_four" {
  vpc_id     = aws_vpc.cnel_vpc.id
  cidr_block = var.cnel_private_subnet_four_cidr_block
  availability_zone = var.az_2

  tags = var.tags
}


resource "aws_internet_gateway" "cnel_igw" {
  vpc_id = aws_vpc.cnel_vpc.id

  tags = var.tags
}


resource "aws_route_table" "cnel_route_table" {
  vpc_id = aws_vpc.cnel_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cnel_igw.id
  }

  tags = var.tags
}


resource "aws_route_table_association" "cnel_public_subnet_one_route_association" {
  subnet_id      = aws_subnet.cnel_public_subnet_one.id
  route_table_id = aws_route_table.cnel_route_table.id
}


resource "aws_route_table_association" "cnel_public_subnet_three_route_association" {
  subnet_id      = aws_subnet.cnel_public_subnet_three.id
  route_table_id = aws_route_table.cnel_route_table.id
}


resource "aws_security_group" "cnel_alb_sg" {
  name        = "cnel_alb_sg"
  vpc_id      = aws_vpc.cnel_vpc.id
  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "cnel_alb_sg_ingress_rule_all" {
  security_group_id = aws_security_group.cnel_alb_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}


resource "aws_vpc_security_group_egress_rule" "cnel_alb_sg_egress_rule_all" {
  security_group_id = aws_security_group.cnel_alb_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol       = "-1"
}


resource "aws_lb" "cnel_application_load_balancer" {
  name = "cnel-application-load-balancer"
  internal = false
  subnets = [aws_subnet.cnel_public_subnet_one.id, aws_subnet.cnel_public_subnet_three.id]
  security_groups = [aws_security_group.cnel_alb_sg.id]

  tags = var.tags
  
}


resource "aws_lb_target_group" "cnel_target_group_eks" {
  name     = "cnel-target-group-eks"
  port     = 30010
  protocol = "HTTP"
  vpc_id   = aws_vpc.cnel_vpc.id
}


locals {
  cnel_node_instance_map = {
    for idx, id in data.aws_instances.cnel_node_instances.ids :
    "node-${idx}" => id
  }
}


resource "aws_lb_target_group_attachment" "cnel_target_group_eks_attachment" {
  for_each = local.cnel_node_instance_map

  target_group_arn = aws_lb_target_group.cnel_target_group_eks.arn
  target_id        = each.value
  port             = 30010
}


resource "aws_lb_listener" "cnel_alb_lb_listener" {
  load_balancer_arn = aws_lb.cnel_application_load_balancer.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.cnel_target_group_eks.arn
  }
}


# EKS


resource "aws_iam_role" "cnel_eks_role" {
  name = "eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["eks.amazonaws.com", "ec2.amazonaws.com"]
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "cnel_eks_policy" {
  role       = aws_iam_role.cnel_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


resource "aws_iam_role_policy_attachment" "cnel_eks_node_policy" {
  role       = aws_iam_role.cnel_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}


resource "aws_iam_role_policy_attachment" "cnel_eks_cni_policy" {
  role       = aws_iam_role.cnel_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


resource "aws_iam_role_policy_attachment" "cnel_eks_ec2_policy" {
  role       = aws_iam_role.cnel_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_eks_cluster" "cnel_eks_cluster" {
  name     = "cnel-eks-cluster"
  role_arn = aws_iam_role.cnel_eks_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.cnel_private_subnet_two.id, aws_subnet.cnel_private_subnet_four.id]
  }
}


resource "aws_eks_node_group" "cnel_node_group" {
  cluster_name    = aws_eks_cluster.cnel_eks_cluster.name
  node_group_name = "cnel-eks-node-group"
  node_role_arn   = aws_iam_role.cnel_eks_role.arn
  subnet_ids      = [aws_subnet.cnel_private_subnet_two.id, aws_subnet.cnel_private_subnet_four.id]

  scaling_config {
    desired_size = 2  # Initial number of nodes
    max_size     = 3  # Maximum number of nodes
    min_size     = 1  # Minimum number of nodes
  }

  instance_types = ["t3.micro"]  # Type of EC2 instances for worker nodes
}