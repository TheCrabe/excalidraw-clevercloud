# 99 — Updates & troubleshooting

## Pull upstream updates

```sh
cd frontend
git fetch upstream
git merge upstream/master       # or rebase, your call
git push origin master          # update your fork
git push clever master          # redeploy on CC
```

Same flow for `room/`.

If you carry local commits (env tweaks, branding), prefer `git rebase upstream/master` to keep history linear.

## Verification checklist

```sh
curl -I https://draw.example.com                              # 200
curl -I https://excalidraw.storage.cleverapps.io/health       # 200
curl -I "https://excalidraw.room.cleverapps.io/socket.io/?EIO=4&transport=polling"   # 200
```

Open the frontend in two browser windows → **+ Share** → live cursor + edits should sync.

## Common issues

### "CORS error" in browser console
Your backends are filtering `Origin`. Check `CORS_ORIGIN` (storage) and `CORS_ALLOW_ORIGIN` (room) match the frontend host **exactly**, including `https://` and no trailing slash.

### "WebSocket connection failed"
- Frontend's `VITE_APP_WS_SERVER_URL` was wrong at build time → rebuild after fixing `.env.production`.
- The room app crashed — `clever logs --app excalidraw.room`.

### "Failed to save scene" on Share
- `VITE_APP_BACKEND_V2_POST_URL` wrong at build time.
- Cellar bucket doesn't exist → re-run `node init-bucket.js` from `storage/`.
- Backend can't reach Cellar → `clever logs --app excalidraw.storage` and check `CELLAR_ADDON_*` envs.

### Build fails on Clever (frontend)
`yarn install` timeouts on small instance? Bump flavor temporarily:
```sh
clever scale --flavor S
clever deploy
clever scale --flavor XS
```

### Terraform `apply` fails on attribute names
Provider 1.11 changed a few resource attribute names from 1.9. Check the [registry docs](https://registry.terraform.io/providers/CleverCloud/clevercloud/latest/docs) for the resource that fails. If the resource you want isn't exposed yet, use the `clever` CLI for that piece and import it into TF later (`terraform import`).

## Useful commands

```sh
clever logs                          # tail current app's logs
clever logs --app excalidraw.room    # tail by name
clever env                           # show env vars
clever restart                       # restart without redeploy
clever scale --flavor S              # change instance size
clever domain                        # list custom domains
clever activity                      # deployment history
```

## References

- [Excalidraw](https://github.com/excalidraw/excalidraw)
- [excalidraw-room](https://github.com/excalidraw/excalidraw-room)
- [Clever Cloud Terraform provider](https://registry.terraform.io/providers/CleverCloud/clevercloud/latest/docs)
- [Clever Cloud Terraform GitHub](https://github.com/CleverCloud/terraform-provider-clevercloud)
- [Cellar add-on docs](https://www.clever.cloud/developers/doc/addons/cellar/)
- [Clever Cloud add-ons CLI](https://www.clever.cloud/developers/doc/cli/addons/)
