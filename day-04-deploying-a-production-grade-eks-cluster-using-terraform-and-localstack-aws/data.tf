data "aws_eks_node_group" "cnel_node_group" {
  cluster_name    = aws_eks_cluster.cnel_eks_cluster.name
  node_group_name = aws_eks_node_group.cnel_node_group.node_group_name
}


data "aws_autoscaling_group" "cnel_node_asg" {
  name = data.aws_eks_node_group.cnel_node_group.resources[0].autoscaling_groups[0].name
}


data "aws_instances" "cnel_node_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [data.aws_autoscaling_group.cnel_node_asg.name]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}
