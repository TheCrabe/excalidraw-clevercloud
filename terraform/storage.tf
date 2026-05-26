resource "clevercloud_nodejs" "storage" {
  name               = "excalidraw.storage"
  region             = var.region
  min_instance_count = 1
  max_instance_count = 4
  smallest_flavor    = "pico"
  biggest_flavor     = "M"

  environment = {
    S3_BUCKET   = clevercloud_cellar_bucket.scenes.id
    CORS_ORIGIN = "https://${var.frontend_domain}"
  }

  dependencies = [clevercloud_cellar.cellar.id]
}
