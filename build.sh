#!/bin/bash

# Variables
cluster_name="cluster-1-test" # If you wanna change the cluster name make sure you change it in the terraform directory variables.tf (name_prefix & environment)
region="YOUR_AWS_REGION"
aws_id="YOUR_AWS_ACCOUNT_ID"
repo_name="goapp-survey" # If you wanna change the repository name make sure you change it in the k8s/app.yml (Image name) 
image_name="$aws_id.dkr.ecr.$region.amazonaws.com/$repo_name:latest"
domain="YOUR_DOMAIN"
namespace="go-survey" # you can keep this variable or if you will change it remember to change the namespace in k8 manifests inside k8s directory
# End of Variables

# update helm repos
helm repo update

# build the infrastructure
echo "--------------------Creating EKS--------------------"
echo "--------------------Creating ECR--------------------"
echo "--------------------Creating EBS--------------------"
echo "--------------------Deploying Ingress--------------------"
echo "--------------------Deploying Monitoring--------------------"
cd terraform && \ 
terraform init
terraform apply -auto-approve
cd ..

# update kubeconfig
echo "--------------------Update Kubeconfig--------------------"
aws eks update-kubeconfig --name $cluster_name --region $region

# remove preious docker images
echo "--------------------Remove Previous build--------------------"
docker rmi -f $image_name || true

# build new docker image with new tag
echo "--------------------Build new Image--------------------"
docker build -t $image_name ./Go-app/

#ECR Login
echo "--------------------Login to ECR--------------------"
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $aws_id.dkr.ecr.$region.amazonaws.com

# push the latest build to dockerhub
echo "--------------------Pushing Docker Image--------------------"
docker push $image_name

# create namespace
echo "--------------------creating Namespace--------------------"
kubectl create ns $namespace || true

# deploy app
echo "--------------------Deploy App--------------------"
kubectl apply -n $namespace -f k8s

# Wait for application to be deployed
echo "--------------------Wait for all pods to be running--------------------"
sleep 60s

# Get ingress URL
echo "--------------------Ingress URL--------------------"
kubectl get ingress go-app-ingress -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo " "
echo " "
echo "--------------------Application URL--------------------"
echo "http://goapp.$domain"

echo "--------------------Alertmanager URL--------------------"
echo "http://alertmanager.$domain"
echo " "

echo "--------------------Prometheus URL--------------------"
echo "http://prometheus.$domain"
echo " "

echo "--------------------Grafana URL--------------------"
echo "http://grafana.$domain"
echo " "
echo " "

echo -e "1. Navigate to your domain cpanel.\n2. Look for Zone Editor.\n3. Add CNAME Record to your domain.\n4. In the name type domain for your application.\n5. In the CNAME Record paste the ingress URL."

