#!/bin/bash

# Check if all required arguments are provided
if [ "$#" -ne 6 ]; then
  echo "Usage: $0 <pipeline_name>  <host> <password> <github_token> <docker_username> <docker_password>"
  exit 1
fi

PIPELINE_NAME="$1"
HOST="$2"
PASSWORD="$3"
GITHUB_TOKEN="$4"
DOCKER_USERNAME="$5"
DOCKER_PASSWORD="$6"

# Clone the GitHub repository
echo "Cloning repository: bureaugewas/vgde_datasets_pipeline"
git clone https://$GITHUB_TOKEN@github.com/bureaugewas/vgde_datasets_pipeline vgdedatasets_deploy

# Step into the cloned repository
cd vgdedatasets_deploy || exit 1

# Remove the existing Docker image
echo "Removing existing Docker image: bureaugewas/vgdedatasets"
docker rmi bureaugewas/vgdedatasets:latest || true

# Step 1: Build Docker image locally
echo "Step 1: Building Docker image locally"
docker build --build-arg GITHUB_TOKEN=$GITHUB_TOKEN -t vgdedatasets .

# Step 2: Push Docker image to Docker Hub
echo "Step 2: Pushing Docker image to Docker Hub"
echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
docker tag vgdedatasets bureaugewas/vgdedatasets:latest
docker push bureaugewas/vgdedatasets:latest

# Step 3: Connect to Raspberry Pi via SSH and create Docker container
echo "Step 3: Creating Docker container on Raspberry Pi"
ssh -o StrictHostKeyChecking=no -i /Users/jurjenwerkaccount/.ssh/id_rsa  "$HOST" \
"echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
 docker stop $PIPELINE_NAME || true && \
 docker rm $PIPELINE_NAME || true && \
 docker pull bureaugewas/vgdedatasets:latest && \
 docker create --name $PIPELINE_NAME -e PIPELINE=$PIPELINE_NAME  -e AZURE_CLIENT_ID=$AZURE_CLIENT_ID -e AZURE_CLIENT_SECRET=$AZURE_CLIENT_SECRET -e AZURE_TENANT_ID=$AZURE_TENANT_ID bureaugewas/vgdedatasets:latest"

# Clean up: Remove the cloned repository
echo "Cleaning up: Removing cloned repository"
cd ..
rm -rf vgdedatasets_deploy

echo "Deployment script completed for pipeline: $PIPELINE_NAME."
