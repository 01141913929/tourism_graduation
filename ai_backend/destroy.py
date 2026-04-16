import os
import subprocess
import boto3
import sys

def run_command(command, cwd=None, exit_on_error=True):
    print(f"🚀 Running: {command}")
    result = subprocess.run(command, shell=True, cwd=cwd)
    if result.returncode != 0 and exit_on_error:
        print(f"❌ Error executing: {command}")
        sys.exit(1)
    return result

def clean_ecr(repo_name, region):
    print(f"\n🧹 Emptying ECR Repository: {repo_name}...")
    try:
        client = boto3.client('ecr', region_name=region)
        response = client.list_images(repositoryName=repo_name)
        image_ids = response.get('imageIds', [])
        
        if not image_ids:
            print("➡️ Repository is already empty.")
            return

        print(f"🗑️ Found {len(image_ids)} images. Deleting...")
        client.batch_delete_image(
            repositoryName=repo_name,
            imageIds=image_ids
        )
        print("✅ Repository emptied.")
    except Exception as e:
        print(f"⚠️ Could not empty repository (it might not exist yet): {e}")

def destroy():
    print("="*50)
    print("⚠️  Egyptian Tourism AI - Teardown / Destroy")
    print("="*50)

    # We need to know the repo name and region. Usually Terraform outputs this.
    print("\n🔍 Fetching ECR details to clear images before Terraform tear-down...")
    try:
        output = subprocess.check_output("terraform output -raw ecr_repository_url", shell=True, cwd="terraform").decode('utf-8').strip()
        aws_region = output.split(".")[3]
        repo_name = output.split("/")[1]
        
        clean_ecr(repo_name, aws_region)
    except Exception as e:
        print("⚠️ Could not fetch ECR URL from Terraform. Proceeding with destroy anyway.")

    print("\n☄️ Running Terraform Destroy...")
    run_command("terraform destroy -auto-approve", cwd="terraform")

    print("\n" + "="*50)
    print("✅ Infrastructure Destroyed Successfully!")
    print("="*50)

if __name__ == "__main__":
    destroy()
