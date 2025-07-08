#!/bin/bash

echo "Starting Ozone cluster..."
docker-compose -f docker/docker-compose.yaml up -d

echo "Waiting for Ozone cluster to be ready..."

# Wait for SCM to be ready
echo "Waiting for SCM to exit safe mode..."
until docker-compose -f docker/docker-compose.yaml exec scm ozone admin safemode status | grep -q "SCM is out of safe mode."; do
  printf "."
  sleep 5
done
echo "SCM is out of safe mode."




echo "Configuring AWS S3 CLI..."

if ! command -v aws &> /dev/null
then
    echo "Error: AWS CLI is not installed. Please install AWS CLI to proceed."
    echo "Refer to: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Replace with actual Ozone S3 gateway endpoint if different
export AWS_ENDPOINT_URL_S3=http://localhost:9878
aws configure set default.s3.signature_version s3v4
aws configure set default.s3.region us-east-1

# Set dummy credentials for AWS CLI to connect to Ozone S3G
export AWS_ACCESS_KEY_ID="ozone_access_key"
export AWS_SECRET_ACCESS_KEY="ozone_secret_key"

echo "Ozone cluster should be ready and AWS S3 CLI configured."

echo "Verifying AWS S3 CLI connection to Ozone S3 Gateway..."
if aws s3 ls > /dev/null 2>&1
then
    echo "AWS S3 CLI successfully connected to Ozone S3 Gateway."
else
    echo "Error: AWS S3 CLI failed to connect to Ozone S3 Gateway. Please check your Ozone cluster and AWS CLI configuration."
    exit 1
fi
