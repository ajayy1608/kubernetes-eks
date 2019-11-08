data "aws_ami" "k8-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.13*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

module "eks" {
  source                        = "./eks"
  instance_type                 = "t3.large"
  aws_private_subnet_ids        = [aws_subnet.app-1.id, aws_subnet.app-2.id]
  aws_subnet_ids                = [aws_subnet.app-1.id, aws_subnet.app-2.id, aws_subnet.web.id]
  aws_vpc_net_id                = aws_vpc.test-vpc.id
  cluster-name                  = "cluster-k8"
  environment                   = "prod"
  aws_image_id                  = data.aws_ami.k8-worker.id
  key_name                      = "test-key"
  eks-version                   = "1.13"
  team_name                     = "DevOps"
  team_owner                    = "aksy121"
  min_size                      = 3
  max_size                      = 3
  desired_capacity              = 3
}

