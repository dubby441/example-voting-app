# AWS EKS Cluster Provisioning with Terraform

## Project Overview

This project provisions an Amazon EKS Kubernetes cluster using Terraform.

## Architecture

- Cloud provider: AWS
- Region: eu-north-1
- Cluster name: voting-capstone
- Infrastructure as Code: Terraform
- Networking: Existing default VPC and its subnets
- Compute: EKS managed node group
- Instance type: t3.medium
- Desired worker nodes: 2 (minimum 1, maximum 2)

## EKS Add-ons

- CoreDNS
- Amazon VPC CNI
- kube-proxy
- EKS Pod Identity Agent

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform 1.5.7 or later
- kubectl

## Deploy

Initialize Terraform:

    terraform init

Format and validate:

    terraform fmt
    terraform validate

Preview changes:

    terraform plan

Apply only after reviewing the plan:

    terraform apply

## Verify

Configure kubectl:

    aws eks update-kubeconfig --region eu-north-1 --name voting-capstone

Check nodes and system pods:

    kubectl get nodes
    kubectl get pods -n kube-system

List installed add-ons:

    aws eks list-addons --cluster-name voting-capstone --region eu-north-1

## Security and Cost

- Never commit Terraform state, saved plans, or credentials.
- Review every Terraform plan before applying changes.
- EKS and EC2 resources can incur ongoing charges.
- Before running terraform destroy, review which resources will be deleted and ensure that workloads and data are no longer needed.

## Current Design

The configuration uses the existing default VPC and enables public access to the Kubernetes API endpoint. Cluster creator administrator permissions are enabled.

## Tools

AWS, Amazon EKS, Terraform, Kubernetes, AWS CLI, kubectl, and Git.
