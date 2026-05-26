locals {
  bucket_suffix = substr(replace(var.organisation, "user_", ""), 0, 8)
}

resource "clevercloud_cellar" "cellar" {
  name   = "excalidraw.cellar"
  region = var.region
}

resource "clevercloud_cellar_bucket" "scenes" {
  cellar_id = clevercloud_cellar.cellar.id
  id        = "excalidraw-scenes-${local.bucket_suffix}"
}
