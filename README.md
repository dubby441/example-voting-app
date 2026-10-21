# Example Voting App — AWS DevOps Capstone

A distributed voting application containerized with Docker and deployed to Amazon EKS using Terraform, GitHub Actions, Amazon ECR, and Helm.

This project demonstrates containerization, infrastructure as code, automated image building and security scanning, Kubernetes deployment, application testing, and Helm rollback.

## Architecture

The application consists of five main components:

* **Vote:** Web interface for submitting votes.
* **Redis:** Queue for incoming votes.
* **Worker:** Processes queued votes and writes them to PostgreSQL.
* **PostgreSQL:** Stores voting data.
* **Result:** Web interface that displays voting totals.

### Deployment architecture

The application runs on Amazon EKS. Terraform provisions the AWS infrastructure, GitHub Actions builds and scans the container images, and Amazon ECR stores the versioned images. Helm deploys and manages the application in Kubernetes.

Architecture diagram: [`docs/architecture.mmd`](docs/architecture.mmd)

## Technology Stack

| Area                   | Technologies                |
| ---------------------- | --------------------------- |
| Application            | Python, Node.js, .NET       |
| Containers             | Docker, Docker Compose      |
| Cloud                  | AWS, Amazon EKS, Amazon ECR |
| Infrastructure as Code | Terraform                   |
| CI/CD                  | GitHub Actions              |
| Image security         | Trivy                       |
| Kubernetes packaging   | Helm                        |
| Messaging              | Redis                       |
| Database               | PostgreSQL                  |
| Source control         | Git, GitHub                 |

## Run Locally with Docker Compose

### Prerequisites

* Docker Desktop or Docker Engine with Docker Compose.
* Git.

### Start the application

Clone your repository and enter the project directory:

```bash
git clone https://github.com/dubby441/example-voting-app.git
cd example-voting-app
```

Validate the Compose configuration and start the application:

```bash
docker compose config --quiet
docker compose up --build
```

Open the applications in your browser:

* **Voting application:** http://localhost:8080
* **Results application:** http://localhost:8081

Stop the application with `Ctrl+C`, then run:

```bash
docker compose down
```

## AWS Infrastructure with Terraform

Terraform configuration is located in [`terraform/eks`](terraform/eks).

The infrastructure and deployment setup includes:

* Amazon EKS Kubernetes cluster.
* Two EC2 worker nodes.
* Amazon ECR repositories for the vote, result, and worker images.
* GitHub Actions OIDC identity provider and IAM role for deployment authentication.
* EKS access permissions for the GitHub Actions deployment role.

The AWS region used for this project is `eu-north-1`.

### Terraform commands

From the Terraform directory:

```bash
cd terraform/eks

terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the plan before applying infrastructure changes:

```bash
terraform apply
```

**Important:** AWS resources can incur charges while running. See the cleanup section before leaving the infrastructure provisioned.

## CI/CD Pipeline

The GitHub Actions workflow is located at [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml).

The pipeline automates the following stages:

1. Validates the Docker Compose configuration.
2. Builds the vote, result, and worker container images.
3. Scans the images using Trivy.
4. Authenticates to AWS using GitHub OIDC.
5. Pushes the images to Amazon ECR.
6. Tags images using the Git commit SHA.
7. Configures access to the Amazon EKS cluster.
8. Deploys or upgrades the application using Helm.

Using commit SHA tags helps identify which source revision produced a particular image.

### GitHub Actions configuration

Configure the required repository variable and secret in **Settings → Secrets and variables → Actions**.

* `AWS_ROLE_ARN`: ARN of the IAM role trusted by GitHub OIDC.
* `DB_PASSWORD`: Database password used by the deployment workflow.

Do not commit credentials, passwords, AWS access keys, or other secrets to the repository.

## Deploying with Helm

The Helm chart is located in [`helm/voting-app`](helm/voting-app).

The release used for the demonstration is `voting-capstone` in the `voting` namespace.

Configure local Kubernetes access:

```bash
aws eks update-kubeconfig \
  --region eu-north-1 \
  --name voting-capstone
```

Inspect the cluster and application:

```bash
kubectl get nodes
kubectl get pods -n voting
kubectl get services -n voting
helm history voting-capstone -n voting
```

### Access the application

Open two terminal windows.

Terminal 1:

```bash
kubectl port-forward -n voting svc/vote 8080:80
```

Terminal 2:

```bash
kubectl port-forward -n voting svc/result 8081:80
```

Visit:

* Voting application: http://localhost:8080
* Results application: http://localhost:8081

Keep both port-forward commands running while testing. These commands provide local access; they do not expose the applications publicly.

## Testing and Validation

The following checks were performed during the capstone demonstration:

* Docker Compose configuration validation passed.
* The Docker Compose integration smoke test passed.
* Vote, result, and worker container images built successfully.
* Trivy image scans completed in the CI/CD workflow.
* GitHub Actions successfully authenticated to AWS and deployed the application.
* Both EKS worker nodes reached `Ready` status.
* All seven application pods were observed running and ready.
* The worker logs confirmed connections to PostgreSQL and Redis and showed processed votes for both options.
* Two different voting options were tested through the web interface.

Useful diagnostic commands:

```bash
kubectl get pods -n voting
kubectl logs deployment/worker -n voting --tail=30
kubectl logs deployment/result -n voting --tail=30
```

## Helm Upgrade and Rollback Demonstration

A controlled upgrade was used to demonstrate recovery from a deployment change.

### 1. Inspect the release history

```bash
helm history voting-capstone -n voting
```

### 2. Upgrade the vote deployment

The vote replica count was temporarily increased from two to three:

```bash
helm upgrade voting-capstone ./helm/voting-app \
  -n voting \
  --reuse-values \
  --set replicaCount.vote=3 \
  --wait
```

The upgrade succeeded, and all three vote replicas became available.

### 3. Roll back to revision 1

```bash
helm rollback voting-capstone 1 -n voting --wait
```

### 4. Verify recovery

```bash
helm history voting-capstone -n voting
kubectl get deployment vote -n voting
kubectl get pods -n voting
```

The rollback succeeded. Helm created revision 3, restored the vote deployment to two replicas, and the application pods remained running and ready.

This demonstrates Helm release history, controlled upgrades, and rollback-based recovery.

## Security and Reliability Considerations

* Container images are pinned to specific base-image digests where configured.
* A `.dockerignore` file is used to exclude unnecessary build-context files.
* GitHub Actions authenticates to AWS using OIDC rather than storing long-lived AWS access keys in GitHub secrets.
* Trivy is used to scan container images.
* Application images are stored in Amazon ECR and tagged with source commit SHAs.
* Kubernetes deployments specify CPU and memory requests and limits.

Security scans should be reviewed for findings; a successful workflow alone does not guarantee that every vulnerability has been eliminated.

## Cleanup and Cost Management

Destroy project infrastructure when the demonstration is complete to avoid ongoing AWS charges.

From `terraform/eks`:

```bash
terraform state list
terraform plan -destroy
```

Review the proposed deletions carefully. If the plan contains only the intended capstone resources, run:

```bash
terraform destroy
```

Confirm the prompt only after checking the resources that will be deleted.

Afterward, verify that the EKS cluster and project ECR repositories have been removed. Keep your source code, Terraform configuration, Helm chart, workflow, architecture diagram, and screenshots in GitHub.

## Project Structure

```text
example-voting-app/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docs/
│   └── architecture.mmd
├── helm/
│   └── voting-app/
├── terraform/
│   └── eks/
├── scripts/
├── vote/
├── result/
├── worker/
├── docker-compose.yml
├── README.md
└── .dockerignore
```

## Learning Outcomes

This capstone provided hands-on practice with:

* Containerizing a multi-service application.
* Validating and running services using Docker Compose.
* Provisioning cloud infrastructure with Terraform.
* Configuring GitHub OIDC authentication to AWS.
* Automating image builds, scanning, and publishing.
* Deploying and troubleshooting applications on Amazon EKS.
* Managing releases and demonstrating rollback with Helm.
* Validating service connectivity and reviewing application logs.
* Documenting a repeatable deployment and cleanup process.

**Repository:** https://github.com/dubby441/example-voting-app
