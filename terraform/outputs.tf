output "frontend_url" {
  value = "https://${[for v in clevercloud_static.frontend.vhosts : v.fqdn][0]}"
}

output "room_url" {
  value = "https://${[for v in clevercloud_nodejs.room.vhosts : v.fqdn][0]}"
}

output "storage_url" {
  value = "https://${[for v in clevercloud_nodejs.storage.vhosts : v.fqdn][0]}"
}

output "cellar_bucket" {
  value = clevercloud_cellar_bucket.scenes.id
}

output "storage_git_url" {
  value = clevercloud_nodejs.storage.deploy_url
}

output "room_git_url" {
  value = clevercloud_nodejs.room.deploy_url
}

output "frontend_git_url" {
  value = clevercloud_static.frontend.deploy_url
}
