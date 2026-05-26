# 02 — Storage backend (custom Node + Cellar)

> 📖 **Background**: [`notions/storage-backend.md`](../notions/storage-backend.md) explains *why* this fits in 50 lines (E2E encryption, URL fragment as secret channel, opaque blob model). Read it first if you've never built against an end-to-end-encrypted scheme — the implementation choices below will make a lot more sense.

## What we're building

A ~50-line Express server with two endpoints:
- `POST /api/v2/scenes` → stores the opaque ciphertext blob in Cellar, returns `{id}`
- `GET  /api/v2/scenes/:id` → streams the blob back

Plus CORS for cross-origin calls from the frontend, and a `/health` route for monitoring. No schema, no auth, no DB — the [notion](../notions/storage-backend.md) explains why this is sufficient.

## Scaffold

From your workspace dir (where you have `frontend/`, `room/`):

```sh
mkdir storage && cd storage
npm init -y
npm pkg set type="module"
npm pkg set scripts.start="node server.js"
npm pkg set engines.node=">=20"
npm install express cors @aws-sdk/client-s3
```

## `storage/server.js`

```js
import express from "express";
import cors from "cors";
import crypto from "node:crypto";
import { S3Client, PutObjectCommand, GetObjectCommand } from "@aws-sdk/client-s3";

const {
  CELLAR_ADDON_HOST,
  CELLAR_ADDON_KEY_ID,
  CELLAR_ADDON_KEY_SECRET,
  S3_BUCKET = "excalidraw-scenes",
  CORS_ORIGIN = "*",
  PORT = 8080,
} = process.env;

const s3 = new S3Client({
  endpoint: `https://${CELLAR_ADDON_HOST}`,
  region: "us-east-1",
  credentials: {
    accessKeyId: CELLAR_ADDON_KEY_ID,
    secretAccessKey: CELLAR_ADDON_KEY_SECRET,
  },
  forcePathStyle: true,
});

const app = express();
app.use(cors({ origin: CORS_ORIGIN }));
app.use(express.raw({ type: "*/*", limit: "20mb" }));

app.get("/health", (_req, res) => res.send("ok"));

app.post("/api/v2/scenes", async (req, res) => {
  const id = crypto.randomUUID();
  await s3.send(new PutObjectCommand({
    Bucket: S3_BUCKET,
    Key: id,
    Body: req.body,
    ContentType: "application/octet-stream",
  }));
  res.json({ id });
});

app.get("/api/v2/scenes/:id", async (req, res) => {
  try {
    const out = await s3.send(new GetObjectCommand({
      Bucket: S3_BUCKET,
      Key: req.params.id,
    }));
    res.set("Content-Type", "application/octet-stream");
    out.Body.pipe(res);
  } catch {
    res.status(404).end();
  }
});

app.listen(PORT, () => console.log(`storage on ${PORT}`));
```

## Deploy via `clever` CLI

```sh
cd storage
git init && git add . && git commit -m "init storage backend"

clever create --type node excalidraw.storage --region par
clever addon create cellar-addon excalidraw.cellar --plan S --region par
clever service link-addon excalidraw.cellar
clever env set S3_BUCKET excalidraw-scenes
clever env set CORS_ORIGIN "*"    # tighten later to your frontend domain

clever deploy
clever open
```

Linking the Cellar add-on auto-injects `CELLAR_ADDON_HOST/KEY_ID/KEY_SECRET` env vars into the app. No manual copy-paste.

## Create the bucket

Cellar is S3-compatible — you could create the bucket with the `aws` CLI, but we already installed `@aws-sdk/client-s3` for the server itself. Reuse it: write a small init script in the same project, no extra tooling.

Create `storage/init-bucket.js`:

```js
import { S3Client, CreateBucketCommand, HeadBucketCommand } from "@aws-sdk/client-s3";

const bucket = process.env.S3_BUCKET || "excalidraw-scenes";

const s3 = new S3Client({
  endpoint: `https://${process.env.CELLAR_ADDON_HOST}`,
  region: "us-east-1",
  credentials: {
    accessKeyId: process.env.CELLAR_ADDON_KEY_ID,
    secretAccessKey: process.env.CELLAR_ADDON_KEY_SECRET,
  },
  forcePathStyle: true,
});

try {
  await s3.send(new HeadBucketCommand({ Bucket: bucket }));
  console.log(`Bucket "${bucket}" already exists — nothing to do.`);
} catch (err) {
  if (err.$metadata?.httpStatusCode !== 404) throw err;
  await s3.send(new CreateBucketCommand({ Bucket: bucket }));
  console.log(`Bucket "${bucket}" created.`);
}
```

Expose it as an npm script and run it:

```sh
npm pkg set scripts.init-bucket="node init-bucket.js"

# Export Cellar credentials + S3_BUCKET into your local shell
eval "$(clever env | grep -E '^(CELLAR_|S3_)' | sed 's/^/export /')"

npm run init-bucket
# → Bucket "excalidraw-scenes" created.
```

> **Why a Node script instead of `aws` CLI?** Same SDK as your `server.js` — if this script succeeds, the server will too (identical credentials, endpoint, signing logic). No extra tool to install. The script is idempotent thanks to `HeadBucketCommand` — safe to re-run anytime.
>
> **Gotcha**: S3 bucket names must be DNS-compatible — lowercase letters, digits, and **hyphens only** (no underscores!). `excalidraw_scenes` fails with `InvalidBucketName`. See [AWS bucket naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html).

## Verify

Get the app URL from its default domain:

```sh
URL="https://$(clever domain | head -n1)"
echo "$URL"
# → https://app-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.cleverapps.io
```

Health check:

```sh
curl -i "$URL/health"
# → HTTP/2 200
# → ok
```

Roundtrip a fake payload through Cellar:

```sh
ID=$(curl -sX POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary "hello-encrypted-payload" \
  "$URL/api/v2/scenes" | jq -r .id)

echo "Stored ID: $ID"

curl -s "$URL/api/v2/scenes/$ID"
# → hello-encrypted-payload
```

If the roundtrip works, your storage backend is correctly wired to Cellar. The frontend will hit these same two endpoints once deployed in Phase 3 — but with encrypted blobs instead of plaintext payloads.

## Next

→ [03 — Collaboration room](03-collaboration-room.md)
