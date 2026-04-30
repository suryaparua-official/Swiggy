variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP zone for the GKE cluster"
  type        = string
  default     = "asia-south1-a"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "swiggy-cluster"
}

variable "node_machine_type" {
  description = "GCE machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "github_org" {
  description = "GitHub organisation or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}
