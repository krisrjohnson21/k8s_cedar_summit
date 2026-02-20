# Cedar Summit — Kubernetes on AWS

A learning project demonstrating containerized application deployment on AWS EKS, provisioned entirely with OpenTofu.

## What This Does

Deploys a Node.js backend service to a Kubernetes cluster on AWS. The application runs as 3 replicas behind a load balancer, with health checks, container image scanning, and infrastructure-as-code managing the full stack.

**Previous version:** This project was originally built on a single EC2 instance with nginx load balancing and systemd process management. This branch re-architects it for Kubernetes to demonstrate container orchestration, managed node groups, and declarative deployments.

## Architecture

```
Internet
   │
   ▼
[ AWS ALB (via LB Controller) ]
   │
   ▼
[ EKS Cluster ]
   ├── Pod: cedar-summit (replica 1)
   ├── Pod: cedar-summit (replica 2)
   └── Pod: cedar-summit (replica 3)
```

**Infrastructure (OpenTofu):** VPC with public/private subnets across 2 AZs, EKS cluster with managed node group, ECR container registry, AWS Load Balancer Controller via Helm, S3 + DynamoDB for remote state.

**Application:** Dockerized Node.js/Express service with health, status, and root endpoints. Multi-stage build, non-root container user, vulnerability scanning on push.

**Kubernetes:** Deployment with 3 replicas, ClusterIP Service for internal routing, Ingress for external access via AWS Load Balancer Controller.

## Project Structure

```
k8s_cedar_summit/
├── bootstrap/              # Remote state backend (run first)
│   ├── providers.tf
│   ├── s3.tf               # S3 bucket + DynamoDB lock table
│   └── variables.tf
├── infra/                  # EKS cluster + supporting infra
│   ├── providers.tf        # AWS, Helm, Kubernetes, HTTP providers
│   ├── vpc.tf              # VPC via terraform-aws-modules/vpc ~> 6.0
│   ├── eks.tf              # EKS via terraform-aws-modules/eks ~> 21.0
│   ├── ecr.tf              # Container registry
│   ├── lb-controller.tf    # AWS LB Controller (IRSA + Helm chart)
│   ├── variables.tf
│   └── outputs.tf
├── restricted/             # Sensitive IAM & OIDC config (separate state)
│   ├── gh-oidc.tf          # GitHub Actions OIDC provider, IAM role, EKS access
│   ├── providers.tf
│   └── variables.tf
├── app/                    # Containerized application
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── server.js
│   ├── package.json
│   └── package-lock.json
└── manifests/              # Kubernetes manifests
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- [OpenTofu](https://opentofu.org/) >= 1.11
- Docker
- kubectl

## Deployment

### 1. Bootstrap remote state

```bash
cd bootstrap
tofu init
tofu apply
```

### 2. Provision infrastructure

EKS and the Load Balancer Controller are deployed in two steps, since the Helm provider needs a running cluster to authenticate against.

```bash
cd infra
tofu init
```

First apply — comment out the `helm_release` block in `lb-controller.tf`, then:

```bash
tofu apply    # ~15 minutes for EKS
```

Configure kubectl once the cluster is up:

```bash
aws eks update-kubeconfig --region us-west-2 --name cedar-summit
```

Second apply — uncomment the `helm_release` block, then:

```bash
tofu apply    # Installs the AWS Load Balancer Controller
```

### 3. Provision restricted resources
```bash
cd restricted
tofu init
tofu apply
```

### 4. Build and push the container image

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $(tofu -chdir=infra output -raw ecr_repository_url)

# Build and push
cd app
docker build -t cedar-summit .
docker tag cedar-summit:latest $(tofu -chdir=../infra output -raw ecr_repository_url):latest
docker push $(tofu -chdir=../infra output -raw ecr_repository_url):latest
```

### 5. Deploy to Kubernetes

The deployment manifest uses an `ECR_REPOSITORY_URL` placeholder. Replace it with your actual ECR URL before applying:

```bash
export ECR_URL=$(tofu -chdir=infra output -raw ecr_repository_url)
sed "s|ECR_REPOSITORY_URL|${ECR_URL}|g" manifests/deployment.yaml | kubectl apply -f -
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingress.yaml
kubectl get pods -w    # Watch pods come up
```

In CI/CD, `ECR_REPOSITORY_URL` is populated from a GitHub Actions secret — no AWS account IDs are committed to the repo.

## Linting

Pre-commit hooks validate manifests and OpenTofu files before each commit:

```bash
brew install pre-commit kubeconform
pre-commit install
pre-commit run --all-files
```

## Cost

EKS cluster ($0.10/hr) + 2x t3.small nodes ($0.04/hr) = **~$3.50/day**. Run `tofu destroy` in `infra/` when not actively working on it.

## Technologies

- **IaC:** OpenTofu 1.11
- **Cloud:** AWS (EKS, ECR, VPC, S3, DynamoDB)
- **Container:** Docker with multi-stage builds
- **Orchestration:** Kubernetes 1.31
- **Runtime:** Node.js 22 / Express
- **Providers:** AWS ~> 6.0, Helm ~> 3.0, Kubernetes ~> 3.0
- **Modules:** terraform-aws-modules/vpc ~> 6.0, terraform-aws-modules/eks ~> 21.0
