# 00 — Prerequisites

## Accounts

- **Clever Cloud** account, personal org. Note your org ID (`user_xxxxxxxx-...`) — visible via `clever profile` or the console URL.
- **GitHub** account with a free org / personal namespace to host the three forks.

## Local tools

| Tool          | Min version | Check                |
|---------------|-------------|----------------------|
| `clever-tools`| 4.0+        | `clever version`     |
| `terraform`   | 1.5+        | `terraform version`  |
| `node`        | 20+         | `node -v`            |
| `gh`          | any         | `gh --version`       |
| `aws` CLI     | any         | `aws --version`      |

Install whatever's missing — `pnpm install -g clever-tools`, Arch repo `terraform`, etc.

## Login to Clever Cloud

```sh
clever login                # opens browser, writes token to ~/.config/clever-cloud/clever-tools.json
clever profile              # confirms identity
```

## Get the Terraform credentials

Same token+secret pair, different consumer:

```sh
cat ~/.config/clever-cloud/clever-tools.json
```

Output looks like:
```json
{ "token": "xxx", "secret": "yyy" }
```

Export them for the Terraform provider:
```sh
export CC_OAUTH_TOKEN="xxx"
export CC_OAUTH_SECRET="yyy"
```

Add these to your shell rc only if you're OK with the secret being on disk — otherwise re-export per session.

## Next

→ [01 — Fork & clone](01-fork-and-clone.md)
