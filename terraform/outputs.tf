output "cluster_name" {
  value = google_container_cluster.swiggy.name
}

output "cluster_location" {
  value = google_container_cluster.swiggy.location
}

output "cluster_endpoint" {
  value     = google_container_cluster.swiggy.endpoint
  sensitive = true
}

output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "github_actions_sa_email" {
  value = google_service_account.github_actions.email
}

output "gke_nodes_sa_email" {
  value = google_service_account.gke_nodes.email
}
