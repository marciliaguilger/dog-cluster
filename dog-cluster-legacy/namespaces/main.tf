resource "kubernetes_namespace" "dog-application" {
  metadata {
    name = "dog-application"
  }
}