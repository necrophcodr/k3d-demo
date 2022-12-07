routes = {
  "k3d.local" = [
    {
      prefixURL = "/grafana(/|$)(.*)"
      service   = "grafana"
      port      = 80
      }, {
      prefixURL = "/prom(/|$)(.*)"
      service   = "prometheus-server"
      port      = 80
      }, {
      prefixURL = "/dashboard(/|$)(.*)"
      service   = "k8s-dashboard-kubernetes-dashboard"
      port      = 80
    }
  ]
  "argo.local" = [
    {
      prefixURL = "/"
      service   = "argo-cd-argocd-server"
      port      = 80
    }
  ]
}

argocd_apps = [ "apps/demo.yaml" ]