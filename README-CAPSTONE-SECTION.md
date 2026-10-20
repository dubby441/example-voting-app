## DevOps Capstone: automated voting app delivery

This repository demonstrates a path from source code to Kubernetes deployment:

- **Docker:** pinned base-image digests, non-root runtime users, and `.dockerignore` files.
- **Terraform:** recreates the EKS cluster and provisions ECR repositories plus a GitHub Actions OIDC role.
- **GitHub Actions:** validates Compose, runs an integration smoke test, builds `linux/amd64` images, scans them with Trivy, pushes commit-SHA-tagged images, and deploys with Helm.
- **Helm:** one chart deploys the vote UI, result UI, worker, Redis, and PostgreSQL.
- **Rollback:** use Helm history and rollback to restore an earlier revision.

### Architecture

See [`docs/architecture.mmd`](docs/architecture.mmd) for the architecture diagram source.

### Deployment URLs during the demo

```bash
kubectl -n voting port-forward svc/vote 8080:80
kubectl -n voting port-forward svc/result 8081:80
```

Open `http://localhost:8080` to vote and `http://localhost:8081` to see results. Run each port-forward in a separate terminal.

### Rollback demonstration

```bash
helm -n voting history voting-capstone
helm -n voting rollback voting-capstone <REVISION>
kubectl -n voting rollout status deployment/vote
```

Replace `<REVISION>` with an earlier working revision shown by Helm history.

### Security and limitations

- GitHub Actions uses OIDC instead of long-lived AWS access keys.
- Set the `AWS_ROLE_ARN` repository variable and `DB_PASSWORD` repository secret in GitHub Settings.
- Trivy scans HIGH and CRITICAL vulnerabilities and reports findings without failing the workflow automatically; document the findings and remediation plan.
- PostgreSQL storage in the demo chart is ephemeral. It is suitable for a capstone demo, not production data.
