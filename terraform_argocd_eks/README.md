## 1. Установка ArgoCD on AWS cluster skruhlik-eks-cluster bu HELM charts version 6.7.14

```

module "argocd" {
  source           = "./terraform_argocd_eks"
  eks_cluster_name = "skruhlik-eks-cluster"
  chart_version    = "6.7.14"
}

```