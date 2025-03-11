// Provider module
provider "google" {
  project = var.gcp_project
}

variable "gcp_project" {
  type = string
}

// Create a PubSub topic
resource "google_pubsub_topic" "main" {
  name = "sandwiches"
}

// Create a service account (GCP's equivalent of an IAM user)
resource "google_service_account" "pubsub_user" {
  account_id   = "sandwiches-subscriber"
  display_name = "PubSub Service Account"
  description  = "Service account for accessing PubSub"
}

// Generate a key for the service account in JSON format
resource "google_service_account_key" "pubsub_user_key" {
  service_account_id = google_service_account.pubsub_user.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"  // This creates a JSON key
}

// Output the private key in Base64 encoded format
// You can decode this to get the actual JSON key file
output "service_account_key" {
  value     = google_service_account_key.pubsub_user_key.private_key
  sensitive = true  // Marks the output as sensitive so it's not shown in logs
}

// Grant the service account subscriber role for the PubSub topic
resource "google_pubsub_topic_iam_binding" "reader" {
  topic    = google_pubsub_topic.main.name
  role     = "roles/pubsub.subscriber"
  members  = [
    "serviceAccount:${google_service_account.pubsub_user.email}"
  ]
}

// Grant the service account explicit permissions to pull from the subscription
resource "google_pubsub_subscription_iam_binding" "subscriber" {
  subscription = google_pubsub_subscription.main.name
  role         = "roles/pubsub.subscriber"
  members      = [
    "serviceAccount:${google_service_account.pubsub_user.email}"
  ]
}

// Create a subscription for the PubSub topic
resource "google_pubsub_subscription" "main" {
  name  = "sandwiches-subscription"
  topic = google_pubsub_topic.main.name
}