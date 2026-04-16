"""
Egyptian Tourism AI — Automated Multi-Service AWS Deployment Script
Supports targeted deployment of microservices (admin/tourist/owner).
"""
import os
import subprocess
import sys
import argparse


def run_command(command, cwd=None, exit_on_error=True):
    """Execute a shell command and print its output."""
    print(f"\nRunning: {command}")
    result = subprocess.run(command, shell=True, cwd=cwd)
    if result.returncode != 0 and exit_on_error:
        print(f"Error executing: {command}")
        sys.exit(1)
    return result


def _get_terraform_output(tf_dir: str, output_name: str) -> str:
    try:
        url = subprocess.check_output(
            f"terraform output -raw {output_name}",
            shell=True,
            cwd=tf_dir,
        ).decode("utf-8").strip()
        return url
    except subprocess.CalledProcessError:
        return ""


def deploy(service: str):
    print("=" * 60)
    print(f"Egyptian Tourism AI — AWS Deployment ({service.upper()})")
    print("=" * 60)

    project_root = os.path.dirname(os.path.abspath(__file__))
    tf_dir = os.path.join(project_root, "terraform")

    # ============================================================
    # Step 1: Terraform Init
    # ============================================================
    print("\nStep 1/6: Initializing Terraform...")
    run_command("terraform init", cwd=tf_dir)

    # ============================================================
    # Step 2: Provision ECR Repositories FIRST
    # ============================================================
    # We always provision both repos so that Terraform doesn't crash on either Lambda
    targets = '-target="aws_ecr_repository.ai_backend_repo" -target="aws_ecr_repository.admin_ai_repo" '
         
    if targets:
         run_command(f"terraform apply {targets} -auto-approve", cwd=tf_dir)

    # ============================================================
    # Step 3: Fetch ECR URLs & Authenticate Docker
    # ============================================================
    print("\nStep 3/6: Authenticating Docker to AWS ECR...")
    
    # We just need any valid ECR URL to get the region/account
    tourist_url = _get_terraform_output(tf_dir, "ecr_repository_url")
    admin_url = _get_terraform_output(tf_dir, "admin_ecr_url")

    primary_url = admin_url if service == "admin" else tourist_url
    
    if not primary_url:
        print(f"Error: Could not get ECR URL. Check Terraform.")
        sys.exit(1)

    aws_region = primary_url.split(".")[3]
    aws_account_id = primary_url.split(".")[0]

    login_cmd = (
        f"aws ecr get-login-password --region {aws_region} | "
        f"docker login --username AWS --password-stdin "
        f"{aws_account_id}.dkr.ecr.{aws_region}.amazonaws.com"
    )
    run_command(login_cmd)

    # ============================================================
    # Step 4: Build & Push Docker Images
    # ============================================================
    print("\nStep 4/6: Building Docker Images (linux/amd64)...")

    # Check for firebase keys before building
    if not os.path.exists(os.path.join(project_root, "secrets", "firebase_credentials.json")):
        print("⚠️ WARNING: secrets/firebase_credentials.json not found! Firestore Cart integration will fail.")
        print("Please ensure you place the service account key there before deploying to production if you need Cart support.")
        print("-" * 60)

    # Always build admin image if requested or if it's implicitly needed by TF
    if service in ["admin", "all"] and admin_url:
        print("\nBuilding Admin Service...")
        admin_tag = f"{admin_url}:latest"
        run_command(f"docker build --provenance=false --platform linux/amd64 -f services/admin/Dockerfile -t {admin_tag} .", cwd=project_root)
        run_command(f"docker push {admin_tag}")

    # Always build tourist image if requested
    if service in ["tourist", "all"] and tourist_url:
        print("\nBuilding Tourist Service...")
        tourist_tag = f"{tourist_url}:latest"
        run_command(f"docker build --provenance=false --platform linux/amd64 -t {tourist_tag} .", cwd=project_root)
        run_command(f"docker push {tourist_tag}")

    # ============================================================
    # Step 5: Deploy ALL Infrastructure
    # ============================================================
    print("\nStep 5/6: Deploying Full Infrastructure...")
    
    # 5.1 Force DynamoDB Creation explicitly so Terraform doesn't skip them
    dynamodb_targets = (
        '-target="aws_dynamodb_table.ws_connections" '
        '-target="aws_dynamodb_table.ai_sessions" '
        '-target="aws_dynamodb_table.user_preferences" '
        '-target="aws_dynamodb_table.ai_carts" '
        '-target="aws_dynamodb_table.ai_coupons" '
        '-target="aws_dynamodb_table.ai_episodes"'
    )
    print("\nStep 5.1: Forcing DynamoDB tables creation...")
    run_command(f"terraform apply {dynamodb_targets} -auto-approve", cwd=tf_dir, exit_on_error=False)

    print("\nStep 5.2: Applying the rest of the infrastructure...")
    run_command("terraform apply -auto-approve", cwd=tf_dir)

    # Force Lambda to pull the latest image if infrastructure says 0 changed
    print("\nStep 5.5: Forcing Lambda Code Update...")
    if service in ["admin", "all"] and admin_url:
        run_command(f"aws lambda update-function-code --function-name admin-ai-service --image-uri {admin_url}:latest", exit_on_error=False)
    
    if service in ["tourist", "all"] and tourist_url:
        tourist_func_name = "egyptian-tourism-ai-planner-deployment-test"
        tourist_http_func_name = "egyptian-tourism-ai-tourist-http-deployment-test"
        run_command(f"aws lambda update-function-code --function-name {tourist_func_name} --image-uri {tourist_url}:latest", exit_on_error=False)
        run_command(f"aws lambda update-function-code --function-name {tourist_http_func_name} --image-uri {tourist_url}:latest", exit_on_error=False)

    # ============================================================
    # Step 6: Display Outputs
    # ============================================================
    print("\n" + "=" * 60)
    print("Deployment Complete! Langfuse Observability is active.")
    print("=" * 60)

    if service in ["tourist", "all"]:
        ws_url = _get_terraform_output(tf_dir, "websocket_api_url")
        http_url = _get_terraform_output(tf_dir, "tourist_http_api_url")
        if ws_url:
            print(f"\nTourist WebSocket URL: {ws_url}")
        if http_url:
            print(f"Tourist HTTP API URL: {http_url}")
            
    if service in ["admin", "all"]:
        admin_api = _get_terraform_output(tf_dir, "admin_api_url")
        if admin_api:
            print(f"\nAdmin HTTP API URL: {admin_api}")

    print("\n=" * 60)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Deploy AI Microservices to AWS")
    parser.add_argument(
        "--service", 
        type=str, 
        choices=["admin", "tourist", "all"], 
        default="all",
        help="Which service to deploy (admin, tourist, or all)"
    )
    args = parser.parse_args()
    deploy(args.service)
