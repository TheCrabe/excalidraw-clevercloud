terraform {
  required_version = ">= 1.5"
  required_providers {
    clevercloud = {
      source  = "CleverCloud/clevercloud"
      version = "~> 1.11"
    }
  }
}

provider "clevercloud" {
  organisation = var.organisation
  # token + secret read from env: CC_OAUTH_TOKEN, CC_OAUTH_SECRET
}
