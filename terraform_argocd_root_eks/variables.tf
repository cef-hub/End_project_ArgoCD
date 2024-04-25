variable "eks_cluster_name" {
  description = "EKS Cluster name to deploy ArgoCD ROOT Application"
  type        = string
  default     = "skruhlik-eks-cluster"
}

variable "git_source_repoURL" {
  description = "GitSource repoURL to Track and deploy to EKS by ROOT Application"
  type        = string
  default     = "https://github.com/cef-hub/End_project_ArgoCD.git"
}

variable "git_source_path" {
  description = "GitSource Path in Git Repository to Track and deploy to EKS by ROOT Application"
  type        = string
  default     = "argocd_app/skruhlik-eks-cluster/applications/"
}

variable "git_source_targetRevision" {
  description = "GitSource HEAD or Branch to Track and deploy to EKS by ROOT Application"
  type        = string
  default     = "HEAD"
}