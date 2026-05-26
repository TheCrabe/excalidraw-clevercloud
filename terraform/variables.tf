variable "organisation" {
  type        = string
  description = "Clever Cloud organisation or user ID (user_xxxx)"
}

variable "region" {
  type    = string
  default = "par"
}

variable "frontend_domain" {
  type        = string
  description = "Public hostname for the frontend. Use a single-level subdomain of cleverapps.io (e.g. excalidraw-foo.cleverapps.io) so it's covered by the wildcard cert. Sub-sub-domains like a.b.cleverapps.io do NOT have a valid TLS cert and break window.crypto.subtle."
  default     = "excalidraw-frontend.cleverapps.io"
}
