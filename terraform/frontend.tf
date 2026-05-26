locals {
  storage_vhost = [for v in clevercloud_nodejs.storage.vhosts : v.fqdn][0]
  room_vhost    = [for v in clevercloud_nodejs.room.vhosts : v.fqdn][0]
}

resource "clevercloud_static" "frontend" {
  name               = "excalidraw.frontend"
  region             = var.region
  min_instance_count = 1
  max_instance_count = 4
  smallest_flavor    = "nano"
  biggest_flavor     = "M"
  build_flavor       = "M"
  redirect_https     = true

  vhosts = [{ fqdn = var.frontend_domain }]

  environment = {
    # Materialize VITE_APP_* env vars into .env.production.local at build time,
    # then run the standard install + build. Vite reads .env.production.local
    # (gitignored upstream) and bakes the values into the bundle.
    CC_PRE_BUILD_HOOK = "printenv | grep '^VITE_APP_' > excalidraw-app/.env.production.local && yarn install --frozen-lockfile && yarn build:app"
    CC_WEBROOT        = "/excalidraw-app/build"

    VITE_APP_WS_SERVER_URL       = "https://${local.room_vhost}"
    VITE_APP_BACKEND_V2_GET_URL  = "https://${local.storage_vhost}/api/v2/scenes/"
    VITE_APP_BACKEND_V2_POST_URL = "https://${local.storage_vhost}/api/v2/scenes"
    VITE_APP_DISABLE_TRACKING    = "true"
  }
}
