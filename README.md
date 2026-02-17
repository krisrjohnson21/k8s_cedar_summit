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
[ AWS Load Balancer ]
   │
   ▼
[ EKS Cluster ]
   ├── Pod: cedar-summit (replica 1)
   ├── Pod: cedar-summit (replica 2)
   └── Pod: cedar-summit (replica 3)
```

**Infrastructure (OpenTofu):** VPC with public/private subnets across 2 AZs, EKS cluster with managed node group, ECR container registry, S3 + DynamoDB for remote state.

**Application:** Dockerized Node.js/Express service with health, status, and root endpoints. Multi-stage build, non-root container user, vulnerability scanning on push.

**Kubernetes:** Deployment with 3 replicas, Service for internal routing, Ingress for external access via AWS Load Balancer Controller.

## Project Structure

```
k8s_cedar_summit/
├── bootstrap/              # Remote state backend (run first)
│   ├── providers.tf
│   └── s3.tf               # S3 bucket + DynamoDB lock table
├── infra/                  # EKS cluster + supporting infra
│   ├── providers.tf
│   ├── vpc.tf              # VPC via terraform-aws-modules/vpc
│   ├── eks.tf              # EKS via terraform-aws-modules/eks
│   ├── ecr.tf              # Container registry
│   ├── variables.tf
│   └── outputs.tf
├── app/                    # Containerized application
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── server.js
│   ├── package.json
│   └── package-lock.json
└── k8s/                    # Kubernetes manifests
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

```bash
cd infra
tofu init
tofu plan
tofu apply    # ~15 minutes for EKS
```

### 3. Configure kubectl

```bash
# Command is printed by tofu output
aws eks update-kubeconfig --region us-west-2 --name cedar-summit
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

```bash
kubectl apply -f k8s/
kubectl get pods -w    # Watch pods come up
```

## Cost

EKS cluster (~$0.10/hr) + 2x t3.small nodes (~$0.04/hr) = **~$3.50/day**. Run `tofu destroy` in `infra/` when not actively working on it.

## Technologies

- **IaC:** OpenTofu 1.11
- **Cloud:** AWS (EKS, ECR, VPC, S3, DynamoDB)
- **Container:** Docker with multi-stage builds
- **Orchestration:** Kubernetes 1.31
- **Runtime:** Node.js 20 / Express
