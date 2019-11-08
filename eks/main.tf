locals {
  tags = {
    "Team"        = var.team_name
    "Environment" = var.environment
    "Owner"       = var.team_owner
  }
}

### CLUSTER IAM ROLE and POLICIES ####
resource "aws_iam_role" "k8-cluster-role" {
  name = "${var.cluster-name}-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

######EKS CUSTOM POLICY for AUTOSCALING CLUSTER MASTER#####
resource "aws_iam_policy" "eks_autoscale_policy" {
  name = "${var.cluster-name}-policy"
  path = "/"

  policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Action": [
"autoscaling:DescribeAutoScalingGroups",
"autoscaling:DescribeAutoScalingInstances",
"autoscaling:DescribeLaunchConfigurations",
"autoscaling:DescribeTags",
"autoscaling:SetDesiredCapacity",
"autoscaling:TerminateInstanceInAutoScalingGroup"
],
"Resource": "*"
}
]
}
EOF
}

resource "aws_iam_policy_attachment" "eks_autoscale_policy_attachment" {
  name       = "eks-cluster-autoscale-policy-attachement"
  roles      = ["${aws_iam_role.k8-cluster-role.name}"]
  policy_arn = "${aws_iam_policy.eks_autoscale_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "k8-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.k8-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "k8-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.k8-cluster-role.name
}

############  SECURITY GROUP #####
resource "aws_security_group" "k8-cluster" {
  name        = "${var.cluster-name}-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.aws_vpc_net_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.cluster-name}-sg"
    },
    local.tags,
  )
}

######## EKS CLUSTER #######
resource "aws_eks_cluster" "k8-cluster" {
  name     = var.cluster-name
  role_arn = aws_iam_role.k8-cluster-role.arn

  vpc_config {
    security_group_ids = [aws_security_group.k8-cluster.id]
    subnet_ids         = var.aws_subnet_ids
  }

  version = var.eks-version

  depends_on = [aws_security_group.k8-cluster]
}

##### EKS WORKER NODES RESOURCES########

resource "aws_iam_role" "k8-worker-role" {
  name = "${var.cluster-name}-worker-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY


  tags = local.tags
}

######EKS CUSTOM POLICY for AUTOSCALING CLUSTER WORKER NODES#####
resource "aws_iam_policy" "k8-worker-policy" {
  name = "${var.cluster-name}-worker-policy"
  path = "/"

  policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Action": [
"autoscaling:DescribeAutoScalingGroups",
"autoscaling:DescribeAutoScalingInstances",
"autoscaling:DescribeLaunchConfigurations",
"autoscaling:DescribeTags",
"autoscaling:SetDesiredCapacity",
"autoscaling:TerminateInstanceInAutoScalingGroup"
],
"Resource": "*"
},
{
"Effect": "Allow",
"Action": [
  "es:*"
],
"Resource": "*"
},
{
      "Effect": "Allow",
       "Action": [
          "ec2:DescribeTags",
          "cloudwatch:PutMetricData"
],
      "Resource": "*"
},
 {
      "Effect": "Allow",
      "Action": [
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:GetCertificate"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVpcs",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeNetworkInterfaces"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:DescribeSSLPolicies",
        "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:DescribeListenerCertificates",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:RemoveTags",
        "elasticloadbalancing:SetIpAddressType",
        "elasticloadbalancing:SetSecurityGroups",
        "elasticloadbalancing:SetSubnets",
        "elasticloadbalancing:SetWebACL",
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:RemoveListenerCertificates"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetServerCertificate",
        "iam:ListServerCertificates"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "waf-regional:GetWebACLForResource",
        "waf-regional:GetWebACL",
        "waf-regional:AssociateWebACL",
        "waf-regional:DisassociateWebACL"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "tag:GetResources",
        "tag:TagResources"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "waf:GetWebACL"
      ],
      "Resource": "*"
    },
    {
     "Effect": "Allow",
     "Action": [
       "route53:ChangeResourceRecordSets"
     ],
     "Resource": [
       "arn:aws:route53:::hostedzone/*"
     ]
   },
   {
     "Effect": "Allow",
     "Action": [
       "route53:ListHostedZones",
       "route53:ListResourceRecordSets"
     ],
     "Resource": [
       "*"
     ]
   },
   {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Action": [
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
         {
        "Action": "autoscaling:DescribeAutoScalingGroups",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "autoscaling:AttachLoadBalancers",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "autoscaling:DetachLoadBalancers",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "autoscaling:DetachLoadBalancerTargetGroups",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "autoscaling:AttachLoadBalancerTargetGroups",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "autoscaling:DescribeLoadBalancerTargetGroups",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "acm:GetCertificate",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "acm:ListCertificates",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "acm:DescribeCertificate",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "iam:ListServerCertificates",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "iam:GetServerCertificate",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "cloudformation:Get*",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "cloudformation:Describe*",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "cloudformation:List*",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "cloudformation:Create*",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "cloudformation:Update*",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
        "Action": "cloudformation:Delete*",
        "Resource": "*",
        "Effect": "Allow"
    },
    {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::*/*",
                "arn:aws:s3:*:*:job/*",
                "arn:aws:s3:::nprd-sis-csv"
            ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "ec2:AttachVolume",
            "ec2:DetachVolume",
            "ec2:CreateTags",
            "ec2:CreateVolume",
            "ec2:DeleteTags",
            "ec2:DeleteVolume",
            "ec2:DescribeTags",
            "ec2:DescribeVolumeAttribute",
            "ec2:DescribeVolumesModifications",
            "ec2:DescribeVolumeStatus",
            "ec2:DescribeVolumes",
            "ec2:DescribeInstances"
        ],
        "Resource": [
            "*"
        ]
    }
]
}
EOF

}

resource "aws_iam_policy_attachment" "k8-worker-policy-attachment" {
  name       = "k8-worker-policy-attachement"
  roles      = [aws_iam_role.k8-worker-role.name]
  policy_arn = aws_iam_policy.k8-worker-policy.arn
}

resource "aws_iam_role_policy_attachment" "k8-worker-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.k8-worker-role.name
}

resource "aws_iam_role_policy_attachment" "k8-worker-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.k8-worker-role.name
}

resource "aws_iam_role_policy_attachment" "k8-worker-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.k8-worker-role.name
}

resource "aws_iam_instance_profile" "k8-worker" {
  name = "${var.cluster-name}-worker-profile"
  role = aws_iam_role.k8-worker-role.name
}

resource "aws_security_group" "k8-worker" {
  name        = "${var.cluster-name}-worker"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.aws_vpc_net_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name"                                      = "${var.cluster-name}-worker"
      "kubernetes.io/cluster/${var.cluster-name}" = "owned"
    },
    local.tags,
  )
}

data "aws_region" "current" {
}

locals {
  k8-worker-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --kubelet-extra-args --node-labels=nodetype=appNode --apiserver-endpoint '${aws_eks_cluster.k8-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.k8-cluster.certificate_authority[0].data}' '${var.cluster-name}' --kube-reserved 'cpu=250m,memory=1Gi,ephemeral-storage=1Gi' --system-reserved 'cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi' --eviction-hard 'memory.available<1Gi,nodefs.available<10%'
USERDATA

}

resource "aws_launch_configuration" "k8-worker-lc" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.k8-worker.name
  image_id                    = var.aws_image_id
  instance_type               = var.instance_type
  name_prefix                 = "${var.cluster-name}-worker-lc-"
  security_groups             = [aws_security_group.k8-worker.id]
  user_data_base64            = base64encode(local.k8-worker-userdata)
  key_name                    = var.key_name

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "k8-worker-asg" {
  desired_capacity     = var.desired_capacity
  launch_configuration = aws_launch_configuration.k8-worker-lc.id
  max_size             = var.max_size
  min_size             = var.min_size
  termination_policies = ["OldestInstance"]
  name                 = "${var.cluster-name}-worker"
  vpc_zone_identifier  = var.aws_private_subnet_ids

  tag {
    key                 = "Name"
    value               = "${var.cluster-name}-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "Team"
    value               = var.team_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = var.team_owner
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

