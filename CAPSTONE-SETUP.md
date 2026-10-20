# Capstone deployment setup

This bundle adds Terraform-managed ECR repositories and GitHub Actions OIDC, one Helm chart for the voting app, and a CI/CD workflow. It also changes the worker and result app to read PostgreSQL credentials from environment variables so a password does not need to be committed.

## 1. Apply files and update app configuration

Extract the ZIP into the repository root, preserving paths. Then run:
```bash
python3 scripts/update-db-config.py
git diff -- worker/Program.cs result/server.js
```
Review the diff. The script is designed to be re-runnable.

## 2. Check GitHub OIDC before Terraform

```bash
aws iam list-open-id-connect-providers
```
If the output already contains `token.actions.githubusercontent.com`, stop before applying `ci.tf`; the existing provider should be imported/reused instead of duplicated.

If it is not present, run:
```bash
cd terraform/eks
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output -raw github_actions_role_arn
```
Review the plan before approval. It adds ECR repos, an IAM role, and EKS access for that role.

## 3. Add GitHub settings

In `dubby441/example-voting-app` → Settings → Secrets and variables → Actions:
- Repository **variable** `AWS_ROLE_ARN`: value from `terraform output -raw github_actions_role_arn`.
- Repository **secret** `DB_PASSWORD`: a strong password of your choice.

The OIDC trust is limited to pushes on `main` in this repository. No long-lived AWS access key is required.

## 4. Validate locally and push

From repo root:
```bash
docker compose config --quiet
docker compose build vote result worker
helm lint helm/voting-app
helm template voting-capstone helm/voting-app   --set images.vote.repository=example/vote   --set images.result.repository=example/result   --set images.worker.repository=example/worker
```
Commit and push to `main`. The GitHub Actions workflow builds amd64 images, runs Trivy scans, pushes images tagged with the commit SHA to ECR, then deploys with Helm.

## 5. Verify deployment and app

```bash
kubectl -n voting get deployments,pods,services
kubectl -n voting rollout status deployment/vote
kubectl -n voting rollout status deployment/result
kubectl -n voting rollout status deployment/worker
```
Terminal 1:
```bash
kubectl -n voting port-forward svc/vote 8080:80
```
Open `http://localhost:8080`. Terminal 2:
```bash
kubectl -n voting port-forward svc/result 8081:80
```
Open `http://localhost:8081`.

## 6. Rollback demo

```bash
helm -n voting history voting-capstone
helm -n voting rollback voting-capstone <REVISION>
kubectl -n voting rollout status deployment/vote
```
Replace `<REVISION>` with a previous revision number from `helm history`. Demonstrate a known-good earlier revision.

## Important caveats

- PostgreSQL uses ephemeral container storage in this demo chart. Data can be lost if the database pod is recreated. This is not production persistence.
- Trivy reports HIGH and CRITICAL findings but does not fail the workflow automatically; review and document findings.
- The workflow builds `linux/amd64`, matching the current `t3.medium` EKS nodes.
