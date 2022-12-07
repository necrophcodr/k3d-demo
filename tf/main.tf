provider "helm" {
  kubernetes {
    config_path = "../.state/kubeconfig"
    config_context = "k3d-k3d-server"
  }
}

provider "kubernetes" {
  config_path = "../.state/kubeconfig"
  config_context = "k3d-k3d-server"
}

resource "helm_release" "nginx-ingress" {
  name = "nginx"
  repository = "https://helm.nginx.com/stable"
  chart = "nginx-ingress"
  version = "0.14.0"
  atomic = true
  timeout = 600
  values = [
    "${file("../kube/values/nginx-ingress.yaml")}"
  ]
}

resource "helm_release" "argocd" {
  name = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  version = "5.4.3"
  atomic = true
  timeout = 600
  values = [
    "${file("../kube/values/${var.env}/argocd.yaml")}"
  ]
}

resource "kubernetes_manifest" "argocd_apps" {
  for_each = toset(var.argocd_apps)
  depends_on = [
    helm_release.argocd
  ]
  manifest = yamldecode(file(each.key))
}

resource "kubernetes_ingress_v1" "ingress" {
  depends_on = [
    helm_release.nginx-ingress
  ]
  metadata {
    name = "default-ingress"
    annotations = {
      "ingress.kubernetes.io/ssl-redirect" = false
      "kubernetes.io/ingress.class" = "nginx"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = false
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "nginx.ingress.kubernetes.io/use-regex" = true
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
      "nginx.ingress.kubernetes.io/proxy-buffering" = false
      "nginx.ingress.kubernetes.io/configuration-snippet" = <<EOT
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $server_name;
        proxy_buffering off;
        proxy_set_header Accept-Encoding "";
EOT
    }
  }
  spec {
    dynamic "rule" {
      for_each = var.routes
      content {
        host = rule.key
        http {
          dynamic "path" {
            for_each = rule.value
            content {
              path = path.value.prefixURL
              path_type = "Prefix"
              backend {
                service {
                  name = path.value.service
                  port {
                    number = path.value.port
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
