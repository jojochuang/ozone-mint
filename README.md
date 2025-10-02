# ozone-mint

This project provides a setup to run MinIO Mint S3 test suite against a Dockerized Apache Ozone cluster.

## Related Projects

*   **MinIO Mint:** The official MinIO Mint repository can be found [here](https://github.com/minio/mint).
*   **Apache Ozone Website:** The official Apache Ozone website is available [here](https://ozone.apache.org/).
*   **Apache Ozone GitHub Repository:** The Apache Ozone GitHub repository can be found [here](https://github.com/apache/ozone).


## Prerequisites

### AWS CLI

The AWS Command Line Interface (CLI) is required to configure access to the Ozone S3 gateway. If you do not have it installed, please follow the instructions below for your operating system.

#### macOS

Using Homebrew:
```bash
brew install awscli
```

#### Linux

Using the bundled installer:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

For other installation methods or operating systems, please refer to the official AWS CLI documentation: [https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Podman

Podman is used to run the MinIO Mint test suite. If you do not have Podman installed, please refer to the official Podman documentation for installation instructions: [https://podman.io/docs/installation](https://podman.io/docs/installation)

On macOS, you will also need to ensure the Podman machine is running:
```bash
podman machine init
podman machine start
```

## Running the Tests

This suite can be run against the default Dockerized Ozone cluster or a local development build.

### 1. Running Against the Default Ozone Cluster

To run the tests against the pre-configured Ozone cluster, execute the `run_mint_tests.sh` script without any arguments.

```bash
./run_mint_tests.sh
```

This script will:
*   Start the Dockerized Ozone cluster using the provided `docker-compose.yaml`.
*   Wait for the Ozone SCM to exit safe mode.
*   Configure the AWS S3 CLI to connect to the Ozone S3 Gateway.
*   Run the MinIO Mint S3 test suite against the Ozone cluster.
*   Stop the Ozone cluster after the tests complete.

### 2. Running Against a Local Development Build

To run the tests against an Ozone cluster built from local source code, you must first produce a full build of the Ozone project. Once built, provide the path to your Ozone repository as an argument to the `run_mint_tests.sh` script.

```bash
./run_mint_tests.sh /path/to/your/ozone/repository
```

The script will then:
*   Locate the compose files in your local build (`hadoop-ozone/dist/target/ozone-*/compose/ozone`).
*   Start the Ozone cluster from your local build.
*   Proceed with the same testing steps as the default execution.

### 3. Configure Ozone S3 Access Keys (Important!)

Before running the tests in either mode, you **must** update the `ACCESS_KEY` and `SECRET_KEY` environment variables in `run_mint_tests.sh` with your actual Ozone S3 access and secret keys. For a default Ozone setup, these are typically `ozone_access_key` and `ozone_secret_key`.

```bash
# run_mint_tests.sh
export ACCESS_KEY="your_ozone_access_key" # <<< REPLACE THIS
export SECRET_KEY="your_ozone_secret_key" # <<< REPLACE THIS
```

## License

This project is licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.