#!/bin/bash

# Check if all required arguments are provided
if [ "$#" -ne 7 ]; then
  echo "Usage: $0 <pipeline_name> <github_token> <docker_username> <docker_password> <azure_client_id> <azure_client_secret> <azure_tenant_id>"
  exit 1
fi

PIPELINE_NAME="$1"
GITHUB_TOKEN="$2"
DOCKER_USERNAME="$3"
DOCKER_PASSWORD="$4"
AZURE_CLIENT_ID="$5"
AZURE_CLIENT_SECRET="$6"
AZURE_TENANT_ID="$7"

# Clone the GitHub repository
echo "Cloning repository: bureaugewas/vgde_datasets_pipeline"
git clone https://$GITHUB_TOKEN@github.com/bureaugewas/vgde_datasets_pipeline vgdedatasets_deploy

# Step into the cloned repository
cd vgdedatasets_deploy || exit 1

# Stop and remove the existing Docker container
echo "Stopping and removing existing Docker container: $PIPELINE_NAME"
docker stop "$PIPELINE_NAME" || true
docker rm "$PIPELINE_NAME" || true

# Remove the existing Docker image
echo "Removing existing Docker image: bureaugewas/vgdedatasets"
docker rmi bureaugewas/vgdedatasets:latest || true

# Step 1: Build Docker image
echo "Step 1: Building Docker image"
export DOCKER_CONFIG=$HOME/.docker
mkdir -p $DOCKER_CONFIG
echo "$DOCKER_PASSWORD" | sudo docker login --username "$DOCKER_USERNAME" --password-stdin
docker build --build-arg GITHUB_TOKEN=$GITHUB_TOKEN -t vgdedatasets .

# Step 2: Push Docker image to Docker Hub
echo "Step 2: Pushing Docker image to Docker Hub"
docker tag vgdedatasets bureaugewas/vgdedatasets:latest
docker push bureaugewas/vgdedatasets:latest

# Step 3: Create Docker container on Raspberry Pi (azure vars should be set in the machine's environment)
echo "Step 3: Creating Docker container on Raspberry Pi"
docker create --name "$PIPELINE_NAME" \
              -e PIPELINE="$PIPELINE_NAME" \
              -e AZURE_CLIENT_ID="$AZURE_CLIENT_ID" \
              -e AZURE_CLIENT_SECRET="$AZURE_CLIENT_SECRET" \
              -e AZURE_TENANT_ID="$AZURE_TENANT_ID" \
              bureaugewas/vgdedatasets:latest

# Clean up: Remove the cloned repository
echo "Cleaning up: Removing cloned repository"
cd ..
rm -rf vgdedatasets_deploy

echo "Deployment script completed for pipeline: $PIPELINE_NAME."

# Manualy add it to "crontab -e":
# 00 02 * * * PIPELINE_NAME=pipeline_test && docker start $PIPELINE_NAME ; docker stop $PIPELINE_NAME