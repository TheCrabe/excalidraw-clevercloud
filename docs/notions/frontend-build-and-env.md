# Notion: Frontend build & env vars

> Conceptual explanation of how the Excalidraw frontend gets configured at build time, and why that constrains the deploy model on Clever Cloud. Read before following [`tutorials/04-frontend.md`](../tutorials/04-frontend.md).

## TL;DR

1. Vite inlines `VITE_APP_*` env vars **at build time** by literal string substitution into the JS bundle.
2. Once built, backend URLs are baked in. Changing them requires a rebuild + redeploy.
3. We use Clever Cloud's `CC_PRE_BUILD_HOOK` to run `yarn build:app` on each deploy, with the right env vars present when the hook fires.
4. We use the **static-apache** runtime (not Node.js) because the output is just static files — no runtime needed.

## Build-time vs runtime env vars

A typical Node app reads env vars **at runtime**:
```js
const dbUrl = process.env.DATABASE_URL;  // resolved when the line executes
```
You can change `DATABASE_URL` and restart the process — new value picked up.

A Vite app does **not** have a runtime — the JS runs in the user's browser. There's no `process` object there, no env vars. So Vite handles `import.meta.env.VITE_APP_FOO` by **string substitution during build**:

```js
// what you write
const wsUrl = import.meta.env.VITE_APP_WS_SERVER_URL;

// what ends up in the bundle (build-time literal)
const wsUrl = "https://excalidraw.room.cleverapps.io";
```

After `yarn build`, the URLs are part of the bundle. Editing `.env.production` after the fact does nothing — the file is read only when Vite runs.

> The `VITE_` prefix is mandatory. Vite refuses to expose any env var that doesn't start with it, as a safety guard against accidentally leaking secrets into the bundle.

## Implication: deploy = rebuild

To change `VITE_APP_WS_SERVER_URL` (say you renamed your room app), the sequence is:
1. Update `.env.production` in the repo
2. Commit + push
3. Clever Cloud receives the push, runs `CC_PRE_BUILD_HOOK` (which calls `yarn build:app`)
4. The build sees the new env, bakes new URLs into the bundle
5. Apache starts serving the rebuilt files

You can't just `clever env set` and restart — that would change env for the *runtime*, but there's no runtime to consume it.

## Why we don't do runtime env injection

A common workaround is to inject env into the page at serve time:
```html
<script>window.__ENV__ = { WS_URL: "..." };</script>
```
Then read `window.__ENV__.WS_URL` from your JS. This lets you change the env without rebuilding.

We don't bother because:
- Excalidraw upstream doesn't do this — we'd have to patch every file that reads an env var (dozens)
- Adds a tiny Node serving layer (you can't serve injected HTML from Apache without templating)
- The URLs change ~never in normal operation. Optimising for "change frequently without rebuild" is YAGNI here.

If you wanted it anyway: you'd run a tiny Express server with `res.render('index.ejs', { env: process.env })` instead of static-apache.

## Why `static-apache` and not `node` runtime on CC

The Excalidraw build output is a pure static bundle: HTML, JS, CSS, images. Two ways to serve it on Clever Cloud:

| Runtime         | What runs at request time            | Pros                           | Cons                              |
|-----------------|--------------------------------------|--------------------------------|-----------------------------------|
| `node`          | Express/serve/http-server process     | Easy if you also want APIs     | Wastes a Node process, costs more |
| `static-apache` | Apache httpd, no application code     | Cheaper, faster, free caching headers | Build hook required for builds |

Since we have no runtime code, `static-apache` wins clearly. We just need:
- `CC_PRE_BUILD_HOOK`: command that runs after CC clones our repo, before serving. We use it to build.
- `CC_WEBROOT`: subdirectory of the repo to serve as root. Excalidraw outputs to `excalidraw-app/build/`, so we point to that.

Apache adds proper `Cache-Control` headers on hashed asset paths (Vite produces files like `main.abc123.js`), giving free long-term caching for free.

## What goes in `.env.production` vs CC env vars

Both work, but they're not equivalent:

| Method                            | Read at  | Best for                                  |
|-----------------------------------|----------|-------------------------------------------|
| File `.env.production` in repo    | build    | Stable public URLs (room, storage)        |
| `clever env set VITE_APP_FOO=bar` | build (via CC's `CC_PRE_BUILD_HOOK` env exposed to it) | Secrets, env-specific overrides, per-deploy values |

For our case, the URLs are public and stable per environment → file is fine. Avoids needing `clever env set` for every var.

## When the build fails on CC

The most common cause: `yarn install` runs out of memory on the smallest flavor. Bump to `S` temporarily:
```sh
clever scale --flavor S
clever deploy
clever scale --flavor XS
```
Scale only matters during the build. Once built, the static files are served by Apache which is featherweight.

## Sources

- [Vite docs — Env Variables and Modes](https://vite.dev/guide/env-and-mode) — canonical reference for `VITE_*` prefix and build-time substitution
- [Vite docs — Building for Production](https://vite.dev/guide/build) — output structure and asset hashing
- [Clever Cloud — Static apps](https://www.clever.cloud/developers/doc/applications/static-apps/) — `CC_PRE_BUILD_HOOK`, `CC_WEBROOT`, Apache config
- [DeepWiki — Backend Service Configuration](https://deepwiki.com/excalidraw/excalidraw/8.2-backend-service-configuration) — list of all `VITE_APP_*` vars Excalidraw recognises
