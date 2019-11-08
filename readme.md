# Deploying Kubernetes on EKS

### Prerequisites:
 - Install Terraform v0.12.6 or newer from [here](https://www.terraform.io/downloads.html).
 - Install awscli using [these](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) instructions.
 - Install kubectl as per [these](https://kubernetes.io/docs/tasks/tools/install-kubectl/) instruction.
 - Have your `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as env vars or in shared secret file etc. (make sure they have required access in your AWS account).
 - Replace `public_key` in aws_infra.tf with your own.
 - Replace AWS account number and IAM use in config_map_aws_auth.yaml

The hard part is done. Now just run `./cluster_up.sh` to have your EKS cluster ready.

Tools & Technologies Used
=======
 - AWS: Provides the complete infrastructure
 - Terraform: To provision AWS infrastructure
 - Kubernetes: As the orchestration layer to manage workloads
 - Docker: For undelying containerization

Architecture & Implementation
=======
The infrastructure is completely AWS based and differnt services have been used EKS being the most significant one apart from networking. Moduler approach has been used a little to write terraform for provisioning the infrastructure. The script `cluster_up.sh` includes the commands required to accomplish the app deployment.

Overview of Steps
=======
Below is the overview of commands in the script `cluster_up.sh`:
```
terraform init && terraform apply -auto-approve
```
The command applies the terraform scripts and provisions the infrastructure. Terraform v0.12.6 has been used for this activity, please make sure it's installed on your system before kicking off the script. Prerequisites to this command includes setting up `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as environment variables or through shared secret file and profile.

```
aws eks update-kubeconfig --name cluster-k8 --region ap-south-1
```
This command gets the configuration of newly created EKS cluster and sets up in your environment so that you can communicate with the kubernetes cluster. Th prerequisites include having `awscli` installed on your system.

```
kubectl apply -f config_map_aws_auth.yaml
```
This command maps the kubernetes cluster roles and users to the AWS roles and users to grant permissions on newly created kubernetes cluster. For this you have to have kubectl command available on your system. Also make sure you replace the AWS account number and IAM user in the yaml file.
