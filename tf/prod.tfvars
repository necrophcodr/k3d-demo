routes = {
  "argo.local" = [
    {
      prefixURL = "/"
      service   = "argo-cd-argocd-server"
      port      = 80
    }
  ]
}

argocd_apps = [ "apps/stage.yaml" ]