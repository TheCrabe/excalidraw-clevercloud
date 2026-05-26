# Notions

Conceptual explanations of the technologies and design choices behind this stack. Read these when you want to understand *why* something works the way it does, not just *how* to set it up.

Tutorials in [`../tutorials/`](../tutorials/) link to the relevant notion at the top of each section. You don't have to read notions to follow the tutorial — but you'll make better decisions on edge cases if you do.

## Available

- [Storage backend](storage-backend.md) — referenced by [`tutorials/02`](../tutorials/02-storage-backend.md). E2E encryption, URL fragment as secret channel, blob-only API.
- [Collaboration protocol](collaboration-protocol.md) — referenced by [`tutorials/03`](../tutorials/03-collaboration-room.md). Socket.IO relay, stateless server, room ID vs encryption key.
- [Frontend build & env vars](frontend-build-and-env.md) — referenced by [`tutorials/04`](../tutorials/04-frontend.md). Vite build-time env substitution, static-apache runtime.
- [Terraform on Clever Cloud](terraform-on-clevercloud.md) — referenced by [`tutorials/05`](../tutorials/05-terraform.md). Provider auth, infra-vs-code split, Cellar as TF state backend.

## Possible future additions

- `cellar-and-s3.md` — Cellar's S3 compatibility surface and quirks (versioning, ACLs, signed URLs)
- `clever-cloud-runtimes.md` — full overview of `clevercloud_*` runtimes (Node vs static vs java vs python)
- `e2e-encryption.md` — abstract over `storage-backend` and `collaboration-protocol` to describe the shared E2E model
