# Tourist AI Deployment Tasks

- `[x]` Update `terraform/lambda.tf` to use `ai_backend_repo` for the tourist lambda.
- `[x]` Update `deploy.py` to trigger the Docker build and Lambda update for the tourist app when `--service tourist` is specified.
- `[x]` Run `python deploy.py --service tourist` to deploy the infrastructure and code.
- `[x]` Verify successful deployment.
