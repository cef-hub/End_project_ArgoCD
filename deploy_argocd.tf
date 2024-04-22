module "argocd" {
  source           = "./terraform_argocd_eks"
  eks_cluster_name = "skruhlik-eks-cluster"
  chart_version    = "6.7.14"
}


module "argocd_skruhlik_root" {
  source             = "./terraform_argocd_root_eks"
  eks_cluster_name   = "skruhlik-eks-cluster"
  git_source_path    = "argocd_app/skruhlik-eks-cluster/applications"
  git_source_repoURL = "https://github.com/cef-hub/End_project_ArgoCD.git"
}

