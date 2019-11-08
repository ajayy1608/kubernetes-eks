#!/bin/bash -e

terraform init && terraform apply -auto-approve
aws eks update-kubeconfig --name cluster-k8 --region ap-south-1
kubectl apply -f config_map_aws_auth.yaml

