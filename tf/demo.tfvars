routes = {
  "k3d.local" = [
    {
      prefixURL = "/grafana"
      service   = "grafana"
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
  "grafana.local" = [
    {
      prefixURL = "/"
      service   = "grafana"
      port      = 80
    }
  ]
}

argocd_apps = [ "apps/demo.yaml" ]
