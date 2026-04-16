# 🇪🇬 Egyptian Tourism AI - AWS Deployment Guide

This repository utilizes **AWS Lambda with Docker containers** to provide a 100% Serverless, deeply scalable architecture. We package the AI application inside Docker to bypass the standard 250MB Lambda ZIP limit and natively compile OS binaries (like `psycopg2` for pgvector) for AWS Linux environments seamlessly.

## Prerequisites
Before deploying, ensure you have the following installed on your machine:
- [AWS CLI](https://aws.amazon.com/cli/) (authenticated via `aws configure`).
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (must be running).
- [Terraform](https://developer.hashicorp.com/terraform/downloads).

## 🚀 1. How to Deploy (CI/CD Automated)
To deploy the entire infrastructure from scratch to AWS, simply run the Python deploy script located in the root of the project:

```bash
python deploy.py
```

### What does `deploy.py` do?
1. Initializes Terraform.
2. Applies **only** the API Container Registry (`ecr.tf`).
3. Uses AWS CLI to authenticate your local Docker daemon with AWS.
4. Builds the Docker image locally optimized for AWS Lambda (`linux/amd64` architecture).
5. Tags and pushes the image into your new ECR.
6. Runs `terraform apply` on the remaining infrastructure (Lambda, API Gateway, Aurora Serverless, DynamoDB) and links them to the new Docker image.


## ☄️ 2. How to Destroy / Teardown
If you are finished testing and wish to stop all AWS billing, run the destroy script:

```bash
python destroy.py
```

### What does `destroy.py` do?
1. Uses `boto3` to securely empty the AWS ECR repository of all Docker images. **Terraform cannot delete an ECR repository if it contains images**.
2. Runs `terraform destroy` to securely tear down databases, servers, and networking.
