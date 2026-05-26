# Tutorials

Step-by-step procedures to deploy the full Excalidraw stack on Clever Cloud. Read in order — each phase depends on the URLs/state produced by the previous one.

For conceptual background ("why is the storage backend so small?", "how does the URL fragment trick work?"), see [`../notions/`](../notions/) — tutorials link to the relevant notion at the top of each section.

## Reading order

1. [00 — Prerequisites](00-prerequisites.md) — tools + accounts + login
2. [01 — Fork & clone](01-fork-and-clone.md) — repo strategy + upstream tracking
3. [02 — Storage backend](02-storage-backend.md) — custom Node + Cellar (S3)
4. [03 — Collaboration room](03-collaboration-room.md) — Socket.IO server
5. [04 — Frontend](04-frontend.md) — build + static deploy
6. [05 — Terraform](05-terraform.md) — reproduce everything in HCL
7. [99 — Updates & troubleshooting](99-updates-troubleshooting.md) — pull upstream, verify, common errors
