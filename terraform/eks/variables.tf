variable "aws_region" {
  description = "AWS region for the Kubernetes cluster"
  type        = string
  default     = "eu-north-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "voting-capstone"
}

variable "kubernetes_version" {
  description = "Kubernetes version supported by EKS in the selected region"
  type        = string
  default     = "1.35"
}