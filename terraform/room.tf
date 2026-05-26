resource "clevercloud_nodejs" "room" {
  name               = "excalidraw.room"
  region             = var.region
  min_instance_count = 1
  max_instance_count = 4
  smallest_flavor    = "pico"
  biggest_flavor     = "M"
  sticky_sessions    = true

  environment = {
    CORS_ALLOW_ORIGIN  = "https://${var.frontend_domain}"
    CC_POST_BUILD_HOOK = "yarn build"
  }
}
