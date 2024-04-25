
## Создали файл main.tf Terraform для раскатывания ArgoCD 

```

data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    token                  = data.aws_eks_cluster_auth.this.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  }
}


resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm" # Official Chart Repo
  chart            = "argo-cd"                              # Official Chart Name
  namespace        = "argocd"
  version          = var.chart_version
  create_namespace = true
  values           = [file("${path.module}/argocd.yaml")]
}

```

## Создали файл argocd.tf Terraform для создания HA-cluster ArgoCD, файл variables.tf и values.tf

```

# Highly Available mode with autoscaling require minimum 3 nodes!
redis-ha:
  enabled: true

controller:
  replicas: 1

server:
  autoscaling:
    enabled: true
    minReplicas: 2

repoServer:
  autoscaling:
    enabled: true
    minReplicas: 2

applicationSet:
  replicas: 2
#----------------------------------------------------------------
# Fixing issue with Stuck Processing for Ingress resource
server:
  config:
    resource.customizations: |
      networking.k8s.io/Ingress:
        health.lua: |
          hs = {}
          hs.status = "Healthy"
          return hs   
#----------------------------------------------------------------
# Change ClusterIP to LoadBalancer  
server:
  service:
    type: LoadBalancer

```

```

variable "eks_cluster_name" {
  description = "EKS Cluster name to deploy ArgoCD"
  type        = string
  default = "skruhlik-eks-cluster"
}

variable "chart_version" {
  description = "Helm Chart Version of ArgoCD: https://github.com/argoproj/argo-helm/releases"
  type        = string
  default     = "6.7.14"
}

```

```

server:
  service:
    type: LoadBalancer

```

## Выполнили terraform сценарий по разворачиванию ArgoCD

```

D:\terraform\End_project_Argocd\ArgoCD\ArgoCD_deploy\terraform_argocd_eks>terraform apply

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

argocd_version = "v2.10.7"
chart_version = "6.7.14"
helm_revision = 1

```

## Создали terraform файлы main.tf шаблон и сам root.yaml для создания root Application ArgoCD, Application1 и Application2

```

main.tf

data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
}


resource "kubernetes_manifest" "argocd_root" {
  manifest = yamldecode(templatefile("${path.module}/root.yaml", {
    path           = var.git_source_path
    repoURL        = var.git_source_repoURL
    targetRevision = var.git_source_targetRevision
  }))
}

```

```

шаблон root.yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name     : root
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    name     : in-cluster
    namespace: argocd
  source:
    repoURL       : "${repoURL}"
    path          : "${path}"
    targetRevision: "${targetRevision}"
  project: default
  syncPolicy:
    automated:
      prune   : true
      selfHeal: true
      
```

```

root.yaml Application

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name     : root
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    name     : in-cluster
    namespace: argocd
  source:
    path   : "argocd_app/skruhlik-eks-cluster/applications"
    repoURL: "https://github.com/cef-hub/End_project_ArgoCD.git"
    targetRevision: HEAD
  project: default
  syncPolicy:
    automated:
      prune   : true
      selfHeal: true
      
```

Application1 app1.yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name     : skruhlik-app
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    name     : in-cluster
    namespace: flask
  source:
    path   : "argocd_app/helmcharts/MyChart_flask"
    repoURL: "https://github.com/cef-hub/End_project_ArgoCD.git"
    targetRevision: HEAD
    helm:
      valueFiles:
      - values.yaml
      parameters:
      - name: "skruhlik-app.container.image"
        value: cefcefcef/devops:ussage 

  project: default
  syncPolicy:
    automated:
      prune   : true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true         

```

```

Application2 app2.yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name     : skruhlik-app2
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    name     : in-cluster
    namespace: flask
  source:
    path   : "argocd_app/helmcharts/MyChart2"
    repoURL: "https://github.com/cef-hub/End_project_ArgoCD.git"
    targetRevision: HEAD
    helm:
      valueFiles:
      - values.yaml
      parameters:
      - name: "skruhlik-app.container.image"
        value: cefcefcef/devops:ussage 

  project: default
  syncPolicy:
    automated:
      prune   : true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true             

```

##  Создали Chart для app1 и app2, values.yaml, deployment.yaml, service.yaml

```

Chart App-HelmChart-1

apiVersion: v2
name       : App-HelmChart-1
description: My Helm chart for Kubernetes
type       : application
version    : 1.0.0   # This is the Helm Chart version
appVersion : "1.0.0" # This is the version of the application being deployed

keywords:
  - flask
  - http
  - https
 
maintainers:
  - name : skruhlik
    email: skruh@nces.by
    url  : nces.by

```

```

Chart App-HelmChart-2

apiVersion: v2
name       : App-HelmChart-2
description: My Helm chart for Kubernetes
type       : application
version    : 1.0.0   # This is the Helm Chart version
appVersion : "1.0.0" # This is the version of the application being deployed

keywords:
  - flask
  - http
  - https
 
maintainers:
  - name : skruhlik
    email: skruh@nces.by
    url  : nces.by

```

```

шаблон deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.name_application.name }}
  labels:
    app: {{ .Values.name_application.name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.name_application.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.name_application.name }}
    spec:
      containers:
      - name: {{ .Values.name_application.name }}
        image: {{ .Values.container.image }}
        ports:
        - containerPort: {{ .Values.pod_port.port }}

```


```

шаблон service.yaml

apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.name_application.name }}-service
spec:
  selector:
    app: {{ .Values.name_application.name }}
  ports:
    - protocol: TCP
      port: {{ .Values.load_balancer_port.port }}
      targetPort: {{ .Values.pod_port.port }}
  type: {{ .Values.service_type.service }}


```


```

values.yaml

# Default Values for my Helm Chart

container:
  image: cefcefcef/devops:ussage 

replicaCount: 1

name_application:
  name: "skruhlik-app2"

load_balancer_port:
  port: 3334

pod_port:
  port: 5555

service_type:
 service: "LoadBalancer"


```

##  Запушили все конфигурации в GitHub root Application и Application1 и Application2

D:\terraform\End_project_Argocd\ArgoCD>git commit -m "git add argocd_app terraform_argocd_eks terraform_argocd_root_eks"
[main 85a2bc4] git add argocd_app terraform_argocd_eks terraform_argocd_root_eks
 9 files changed, 48 insertions(+), 30 deletions(-)
 create mode 100644 terraform_argocd_eks/values.yaml

D:\terraform\End_project_Argocd\ArgoCD>git remote -v
argocd  https://github.com/cef-hub/End_project_ArgoCD.git (fetch)
argocd  https://github.com/cef-hub/End_project_ArgoCD.git (push)

D:\terraform\End_project_Argocd\ArgoCD>git push -u argocd
Enumerating objects: 35, done.
Counting objects: 100% (35/35), done.
Delta compression using up to 8 threads
Compressing objects: 100% (18/18), done.
Writing objects: 100% (19/19), 2.33 KiB | 595.00 KiB/s, done.
Total 19 (delta 6), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (6/6), completed with 6 local objects.
To https://github.com/cef-hub/End_project_ArgoCD.git
   20b9505..85a2bc4  main -> main
branch 'main' set up to track 'argocd/main'.


##  Создали root Application и Application1 и Application2

```

D:\terraform\End_project_Argocd\ArgoCD\ArgoCD_deploy\terraform_argocd_root_eks>terraform apply


Plan: 1 to add, 0 to change, 0 to destroy.

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.


```

## Добавили установочный репозиторий prometheus-community, создали namespace prometheus, запустили helm установку prometheus-community

```

D:\terraform\End_project_Argocd\ArgoCD>helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

"prometheus-community" has been added to your repositories

D:\terraform\End_project_Argocd\ArgoCD>kubectl create namespace prometheus
namespace/prometheus created

D:\terraform\End_project_Argocd\ArgoCD>helm install prometheus prometheus-community/kube-prometheus-stack --namespace prometheus --set server.service.type=LoadBalancer
NAME: prometheus
LAST DEPLOYED: Thu Apr 25 13:20:06 2024
NAMESPACE: prometheus
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace prometheus get pods -l "release=prometheus"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.

```

## Результат выполнения действий

# apply argocd helm

![apply argocd helm](https://github.com/cef-hub/End_project_ArgoCD/blob/main/Pictures/apply%20argocd%20helm.png?raw=true)

# apply argocd root and app

![apply argocd root and app](https://github.com/cef-hub/End_project_ArgoCD/blob/main/Pictures/apply%20argocd%20root%20and%20app.png?raw=true)

# argocd app1 pod1

![argocd app1 pod1](https://github.com/cef-hub/End_project_ArgoCD/blob/main/Pictures/argocd%20app1%20pod1.png?raw=true)

# postman app1

![postman app1](https://github.com/cef-hub/End_project_ArgoCD/blob/main/Pictures/postman%20app1.png?raw=true)

# prometheus_dash

![prometheus_dash](https://github.com/cef-hub/End_project_ArgoCD/blob/main/Pictures/prometheus_dash.png?raw=true)

