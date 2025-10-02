#!/bin/bash

# Check if a command-line argument (path to local build) is provided
if [ -z "$1" ]; then
  # If no argument, start Ozone from the docker-compose file in the docker directory
  COMPOSE_FILE="docker/docker-compose.yaml"
  echo "No local build path provided. Starting Ozone from $COMPOSE_FILE."
  docker-compose -f "$COMPOSE_FILE" up -d

  echo "Waiting for Ozone cluster to be ready..."

  # Wait for SCM to be ready
  echo "Waiting for SCM to exit safe mode..."
  until docker-compose -f "$COMPOSE_FILE" exec scm ozone admin safemode status | grep -q "SCM is out of safe mode."; do
    printf "."
    sleep 5
  done
  echo "SCM is out of safe mode."
else
  # If an argument is provided, use it as the path to a local development build
  OZONE_DEV_PATH=$1
  # Use a wildcard for the version to be more robust
  COMPOSE_DIR_PATTERN="$OZONE_DEV_PATH/hadoop-ozone/dist/target/ozone-*/compose/ozone"
  COMPOSE_DIR=$(ls -d $COMPOSE_DIR_PATTERN 2>/dev/null | head -n 1)

  if [ -z "$COMPOSE_DIR" ] || [ ! -d "$COMPOSE_DIR" ]; then
      echo "Error: Could not find compose directory matching $COMPOSE_DIR_PATTERN"
      exit 1
  fi

  echo "Starting Ozone cluster from local build at $COMPOSE_DIR"

  # Run the cluster start script from its directory in a subshell, setting comprehensive memory limits to avoid OOM errors.
  (cd "$COMPOSE_DIR" && \
    export OZONE_SCM_OPTS="-Xmx1g -XX:MaxMetaspaceSize=256m" && \
    export OZONE_OM_OPTS="-Xmx1g -XX:MaxMetaspaceSize=256m" && \
    export OZONE_DATANODE_OPTS="-Xmx1g -XX:MaxMetaspaceSize=256m" && \
    OZONE_DATANODES=3 ./run.sh -d)

  echo "Waiting for Ozone cluster to be ready..."

  # Add a pause and a diagnostic command to check the state of the services.
  echo "Pausing for 10 seconds to let services initialize..."
  sleep 10
  echo "Checking the status of docker-compose services:"
  COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yaml"
  docker-compose -f "$COMPOSE_FILE" ps

  # Wait for the SCM service to become responsive enough for exec commands
  echo "Waiting for SCM service to become responsive..."
  until docker-compose -f "$COMPOSE_FILE" exec scm true > /dev/null 2>&1; do
    printf "!"
    sleep 5
  done
  echo "SCM service is responsive."

  # Now, wait for SCM to be ready (exit safe mode)
  echo "Waiting for SCM to exit safe mode..."
  until docker-compose -f "$COMPOSE_FILE" exec scm ozone admin safemode status | grep -q "SCM is out of safe mode."; do
    printf "."
    sleep 5
  done
  echo "SCM is out of safe mode."
fi


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