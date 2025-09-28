# Gururaj Rathod - AWS DevOps Portfolio Project

This repository contains a complete, end-to-end portfolio project demonstrating a modern DevOps workflow on AWS. The project deploys a simple web application into a Kubernetes cluster, fully automated with a CI/CD pipeline using GitHub Actions and infrastructure provisioned with Terraform.

## Project Goal

The primary goal of this project is to showcase proficiency in a range of essential DevOps tools and practices, including:
- **Infrastructure as Code (IaC):** Using Terraform to define and manage all cloud resources in a repeatable and version-controlled manner.
- **CI/CD Automation:** Building a robust pipeline with GitHub Actions to automatically build, test, and deploy the application.
- **Containerization:** Using Docker to package the application and its dependencies.
- **Orchestration:** Deploying the containerized application to a managed Kubernetes service (Amazon EKS).
- **Cloud Services:** Leveraging core AWS services like VPC, EKS, ECR, RDS, and ElastiCache.
- **GitOps Principles:** Using a Git repository as the single source of truth for both application code and infrastructure definitions.

---

## Core Technologies

- **Cloud Provider:** Amazon Web Services (AWS)
- **IaC:** Terraform
- **CI/CD:** GitHub Actions
- **Containerization:** Docker
- **Orchestration:** Kubernetes (Amazon EKS)
- **Deployment:** Helm
- **Application:** Node.js / Express

---

## Architecture

The infrastructure consists of the following key components provisioned by Terraform:

1.  **VPC:** A custom Virtual Private Cloud with public and private subnets across multiple Availability Zones for high availability.
2.  **EKS Cluster:** A managed Kubernetes cluster where the application runs. Worker nodes are placed in private subnets for security.
3.  **ECR:** A private Docker container registry to store the application images.
4.  **RDS (PostgreSQL):** A managed relational database instance (though not used by the simple portfolio app, it is provisioned to demonstrate capability).
5.  **ElastiCache (Redis):** A managed in-memory cache (also provisioned to demonstrate capability).
6.  **IAM Roles:** Secure, fine-grained permissions for the EKS cluster, worker nodes, and the GitHub Actions CI/CD pipeline (using OIDC for passwordless authentication).

*(A visual diagram of the architecture can be found in `docs/architecture.mmd`)*

---

## CI/CD Pipeline Workflow

The pipeline is defined in `.github/workflows/ci-cd.yml` and triggers on every push to the `main` branch.

1.  **Build and Push:**
    - The job checks out the code.
    - It authenticates to AWS using an OIDC IAM Role.
    - It reads the ECR repository URL from the Terraform state.
    - It builds the Node.js application into a Docker image.
    - It tags the image with a unique identifier and pushes it to the private Amazon ECR repository.

2.  **Deploy to EKS:**
    - This job runs after the image is successfully pushed.
    - It configures `kubectl` to connect to the EKS cluster.
    - It uses Helm to perform a rolling update, deploying the new container image to the Kubernetes cluster with zero downtime.

---

## Deployment

To deploy this project:

1.  **Fork this repository.**
2.  **Create AWS Resources:** Manually create the S3 bucket and DynamoDB table for the Terraform backend.
3.  **Configure GitHub Secrets:** Set the `AWS_ROLE_TO_ASSUME` secret in your repository settings to point to the ARN of the GitHub Actions deployer role created by Terraform.
4.  **Run Terraform:** Run `terraform init` and `terraform apply` from the `infrastructure` directory to provision all the cloud resources.
5.  **Push a Commit:** Push a commit to the `main` branch to trigger the GitHub Actions pipeline, which will build and deploy the application.