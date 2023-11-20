#!/bin/bash
namespace="go-survey"
repo_name="goapp-survey"

#ECR Login
echo "--------------------Login to ECR--------------------"
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $aws_id.dkr.ecr.$region.amazonaws.com

# delete Docker-img from ECR
echo "--------------------Deleting ECR-IMG--------------------"
aws ecr batch-delete-image --repository-name $repo_name --image-ids imageTag=latest

# delete deployment
echo "--------------------Deleting Deployment--------------------"
kubectl delete -n $namespace -f k8s/

# delete namespace
echo "--------------------Deleting Namespace--------------------"
kubectl delete ns $namespace

# delete AWS resources
echo "--------------------Deleting AWS Resources--------------------"
cd terraform && \
terraform destroy -auto-approve
