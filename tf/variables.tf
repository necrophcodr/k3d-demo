variable "routes" {
  type = map(list(object({
    prefixURL = string
    service = string
    port = number
  })))
  default = {
    "k3d.local" = [
      {
        prefixURL = "/grafana"
        service = "grafana"
        port = 80
      },{
        prefixURL = "/prom"
        service = "prometheus-server"
        port = 80
      }
    ]
    "argo.local" = [
      {
        prefixURL = "/"
        service = "argo-cd-argocd-server"
        port = 80
      }
    ]
  }
}

variable "argo" {
  description = "argo-cd configuration"
  type = object({
    domain = string
    prefixURL = string
  })
  default = {
    domain = "argo.local"
    prefixURL = "/"
  }
}

variable "prometheus" {
  description = "Prometheus configuration"
  type = object({
    domain = string
    prefixURL = string
  })
  default = {
    domain = "localhost"
    prefixURL = "/prom"
  }
}

variable "grafana" {
  description = "Grafana configuration"
  type = object({
    domain = string
    prefixURL = string
  })
  default = {
    domain = "localhost"
    prefixURL = "/grafana"
  }
}

variable "argocd_apps" {
  description = "A list of YAML files containing ArgoCD applications"
  type = list(string)
  default = []
}

variable "env" {
  description = "Deployment environment [demo|stage|prod]"
  type = string

  validation {
    condition = contains(["demo","prod","stage"], var.env)
    error_message = "var.env MUST BE one of 'demo','stage', or 'prod'."
  }  
}