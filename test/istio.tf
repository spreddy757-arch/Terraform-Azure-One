# =====================================================
# Istio Service Mesh Configuration
# =====================================================
# Installs Istio using the official Helm charts with
# default configuration values:
# 1. base    - Istio CRDs and cluster-wide resources
# 2. istiod  - Istio control plane
# 3. gateway - Istio ingress gateway
# =====================================================

locals {
  istio_chart_repository = "https://istio-release.storage.googleapis.com/charts"
  istio_version          = "1.29.3"
}

# Istio system namespace
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      "app.kubernetes.io/name" = "istio"
      environment              = var.environment
    }
  }

  depends_on = [time_sleep.wait_for_cluster]
}

# Istio base chart (CRDs and cluster-wide resources)
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = local.istio_chart_repository
  chart      = "base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = local.istio_version

  timeout = 600
  wait    = true

  depends_on = [kubernetes_namespace.istio_system]
}

# Istiod control plane (default configuration)
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = local.istio_chart_repository
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = local.istio_version

  timeout       = 600
  wait          = true
  wait_for_jobs = true

  depends_on = [helm_release.istio_base]
}

# Istio ingress gateway (default configuration)
resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = local.istio_chart_repository
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = local.istio_version

  timeout = 600
  wait    = true

  depends_on = [helm_release.istiod]
}
