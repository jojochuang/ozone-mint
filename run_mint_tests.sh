#!/bin/bash

# Step 1: Run setup_ozone.sh to start the Ozone cluster and configure AWS S3 CLI
echo "Setting up Ozone cluster and AWS S3 CLI..."
./setup_ozone.sh "$@"

# Step 2: Check for Podman installation
if ! command -v podman &> /dev/null
then
    echo "Error: Podman is not installed. Please install Podman to proceed."
    echo "For example, on macOS: brew install podman"
    echo "On Linux (Debian/Ubuntu): sudo apt update && sudo apt install podman"
    echo "On Linux (Fedora/RHEL): sudo dnf install podman"
    exit 1
fi



# Check if Podman machine is running (for macOS/Windows)
if [[ "$(uname)" == "Darwin" || "$(uname)" == "MINGW" ]]; then
    if ! podman machine list | grep -qi Running;
    then
        echo "Error: Podman machine is not running."
        echo "Please initialize and start the Podman machine:"
        echo "  podman machine init"
        echo "  podman machine start"
        exit 1
    fi
fi

# Step 3: Configure environment variables for MinIO Mint
# IMPORTANT: Replace these placeholder values with your actual Ozone S3 access and secret keys.
# For a default Ozone setup, these might be 'ozone_access_key' and 'ozone_secret_key'.
export SERVER_ENDPOINT="host.containers.internal:9878"
export ACCESS_KEY="testkey"
export SECRET_KEY="testsecret"
export ENABLE_HTTPS=0 # Set to 1 if you configure HTTPS for Ozone S3G

echo "MinIO Mint environment variables configured:"
echo "  SERVER_ENDPOINT: $SERVER_ENDPOINT"
echo "  ACCESS_KEY: $ACCESS_KEY (Please ensure this is your actual Ozone S3 access key)"
echo "  SECRET_KEY: $SECRET_KEY (Please ensure this is your actual Ozone S3 secret key)"
echo "  ENABLE_HTTPS: $ENABLE_HTTPS"

# Step 4: Run MinIO Mint using Podman
MINT_CONTAINER_NAME="minio-mint-tests"
MINT_IMAGE="minio/mint" # Official MinIO Mint Docker image

echo "Running MinIO Mint tests against Ozone S3G..."
podman run --rm --name $MINT_CONTAINER_NAME \
  -e SERVER_ENDPOINT=$SERVER_ENDPOINT \
  -e ACCESS_KEY=$ACCESS_KEY \
  -e SECRET_KEY=$SECRET_KEY \
  -e ENABLE_HTTPS=$ENABLE_HTTPS \
  $MINT_IMAGE

echo "MinIO Mint tests completed. Review the output above for test results."

# Step 5: Stop Ozone cluster
echo "Stopping Ozone cluster..."
if [ -z "$1" ]; then
  # No argument was provided, so shut down the default cluster
  docker-compose -f docker/docker-compose.yaml down
else
  # An argument was provided, so we need to find the compose directory again and shut it down.
  OZONE_DEV_PATH=$1
  COMPOSE_DIR_PATTERN="$OZONE_DEV_PATH/hadoop-ozone/dist/target/ozone-*/compose/ozone"
  COMPOSE_DIR=$(ls -d $COMPOSE_DIR_PATTERN 2>/dev/null | head -n 1)
  if [ -n "$COMPOSE_DIR" ] && [ -d "$COMPOSE_DIR" ]; then
    (cd "$COMPOSE_DIR" && docker-compose down)
  else
    echo "Warning: Could not find compose directory to shut down the development cluster."
  fi
fi

echo "Script finished."
