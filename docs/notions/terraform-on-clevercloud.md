# Notion: Terraform on Clever Cloud

> Conceptual explanation of the Clever Cloud Terraform provider's model — what it manages, what it deliberately doesn't, and how it fits into the "infra vs code" split. Read before following [`tutorials/05-terraform.md`](../tutorials/05-terraform.md).

## TL;DR

1. The provider authenticates with the same OAuth1 **token + secret** as `clever-tools`, via `CC_OAUTH_TOKEN` + `CC_OAUTH_SECRET` env vars.
2. Two resource families: `clevercloud_<runtime>` for **apps** (compute slots) and `clevercloud_addon` for **managed services** (Cellar, Postgres, ...).
3. Terraform provisions **the app's slot, config, env vars, vhosts, add-ons** — but NOT your code. Code shipping is a separate `git push <deploy_url> master` step.
4. Provider is in `1.x` — minor versions can have breaking changes. Pin tightly with `~> 1.11`.

## What the provider creates

| Resource                          | What it provisions                                                |
|-----------------------------------|-------------------------------------------------------------------|
| `clevercloud_nodejs`              | A Node.js app slot (compute, flavor, scaling, env, vhosts)        |
| `clevercloud_static`              | A static-Apache app slot (Apache runtime, `CC_PRE_BUILD_HOOK`, `CC_WEBROOT`) |
| `clevercloud_python`, `_java`, … | Same pattern for other runtimes                                   |
| `clevercloud_addon`               | Any managed add-on by `provider_id` (`cellar-addon`, `postgresql-addon`, ...) |
| `clevercloud_oauth_consumer`      | OAuth1 consumers, for apps that need to call CC's API             |
| `clevercloud_vulnerability_scanner`| Security scanner config (new in 1.11)                            |

What you get **back** for each app:
- `deploy_url`: the git URL to push your code to
- `vhost`: the default `*.cleverapps.io` hostname
- `additional_vhosts`: any custom domains you added

## What the provider does NOT do

This list matters because newcomers expect Terraform to be a full deploy tool:

- ❌ **Push your code.** No `git push` happens. You wire `clever` as a git remote per app and push manually (or via CI).
- ❌ **Build your code.** Build hooks (`CC_PRE_BUILD_HOOK`) are env vars TF sets, but the actual build runs on CC when you push.
- ❌ **Provision data inside add-ons.** Creating a Cellar add-on does NOT create buckets. Creating a Postgres add-on does NOT run your schema migrations. You do those out-of-band.
- ❌ **Manage DNS.** Adding `additional_vhosts` registers the hostname with the app, but you still need to create the CNAME at your DNS provider.
- ❌ **Manage CI/CD.** No "deploy on push from GitHub" wiring — you build that separately (GitHub Actions, your own scripts, etc.).

## Why separate "infra" from "code shipping"

This is a deliberate design choice that aligns with standard CD practice:

- **Infra** (Terraform) = "what apps and services exist, how they're configured, what env they have"
- **Code shipping** (`git push`) = "what version of the app is currently running"

The decoupling means:
- You can rebuild your infra from scratch (e.g. spin up a staging env) without redeploying every app version. The infra exists in seconds; you push code into the slots whenever.
- Your code repo and your infra repo can evolve independently. Same TF config, different code versions = different deployments.
- Rollbacks are git operations on the code side, not Terraform operations on the infra side. `terraform apply` shouldn't ever roll back a release.

If you've used AWS CDK or Pulumi, this might feel weird — those frameworks tend to bundle code packaging into the infra deploy. CC's TF provider is more old-school: infra is infra, code is code.

## The auth model

Clever Cloud's API uses **OAuth1** (yes, OAuth1 — the older spec with HMAC signing). The `clever-tools` CLI authenticates once via browser flow and stores a `{token, secret}` pair in `~/.config/clever-cloud/clever-tools.json`.

The Terraform provider reuses the **exact same token+secret pair**. You don't need a separate API key. Export them as env vars:

```sh
export CC_OAUTH_TOKEN="$(jq -r .token  ~/.config/clever-cloud/clever-tools.json)"
export CC_OAUTH_SECRET="$(jq -r .secret ~/.config/clever-cloud/clever-tools.json)"
```

The provider signs every request with HMAC-SHA1 using the secret. The token identifies you to the API.

For CI/automation: create a dedicated CC user, log it in once, copy the token+secret to your CI secrets. Don't share your personal token across machines.

## The `dependencies` attribute on apps

When you write:
```hcl
resource "clevercloud_nodejs" "storage" {
  # ...
  dependencies = [clevercloud_addon.cellar.id]
}
```

This does **two** things, not just one:
1. **Provisioning order**: Terraform creates the add-on before the app (because the app references the add-on's `id`).
2. **Runtime linkage**: CC's API sees the link and **auto-injects the add-on's credential env vars** into the app's environment. For Cellar, that's `CELLAR_ADDON_HOST`, `CELLAR_ADDON_KEY_ID`, `CELLAR_ADDON_KEY_SECRET`.

Same as what `clever service link-addon` does manually via CLI.

## Provider version stability

The provider is at `1.11.0` as of mid-2026, still pre-2.0. **Minor versions have shipped breaking changes** — for example attribute renames or default behavior changes between `1.9 → 1.10 → 1.11`. Pin tightly:

```hcl
clevercloud = {
  source  = "CleverCloud/clevercloud"
  version = "~> 1.11"     # accept 1.11.x, reject 1.12+
}
```

Check the [changelog](https://www.clever.cloud/developers/changelog/) before bumping. The CC team is good about documenting breaks.

## Cellar as a remote backend for Terraform state itself

For shared use (you + a teammate, or just you across multiple machines), local `terraform.tfstate` is a pain. Cellar speaks S3, and Terraform's S3 backend works against it:

```hcl
terraform {
  backend "s3" {
    bucket   = "tfstate-excalidraw"
    key      = "main.tfstate"
    region   = "us-east-1"
    endpoint = "https://cellar-c2.services.clever-cloud.com"
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}
```

You'd create the `tfstate-excalidraw` bucket out-of-band (as Phase 2 does for `excalidraw-scenes`), and pass `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars pointing to your Cellar credentials. Bonus: enable bucket versioning to get free state history.

## When to use TF vs the CLI

Both are valid for CC. Rule of thumb:

- **CLI (`clever`)** = exploration, one-off setup, single-developer projects you'll deploy by hand for the next 6 months.
- **Terraform** = anything that needs to be reproducible: shared environments, dev/staging/prod parity, disaster recovery, onboarding a new contributor.

The two **interoperate cleanly**: apps created by `clever create` can later be imported into TF (`terraform import clevercloud_nodejs.foo app_xxxxxxxx`), and apps created by TF can be managed by `clever` after the fact (the `.clever.json` link file is just a path-to-id mapping).

## Sources

- [Clever Cloud Terraform provider — Registry docs](https://registry.terraform.io/providers/CleverCloud/clevercloud/latest/docs) — full resource reference
- [Terraform provider source on GitHub](https://github.com/CleverCloud/terraform-provider-clevercloud)
- [Clever Cloud Terraform changelog](https://www.clever.cloud/developers/changelog/) — track breaking changes per version
- [Clever Cloud — Marketplace APIs & Tools](https://developers.clever-cloud.com/doc/marketplace/) — OAuth1 auth model docs
- [Terraform S3 backend with custom endpoint](https://developer.hashicorp.com/terraform/language/backend/s3) — for using Cellar as TF state backend
