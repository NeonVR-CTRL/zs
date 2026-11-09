# ZeroShift Studio — Full Audit & Cloudflare Worker Deploy

## Files created in `deploy/`

| File | Purpose |
|---|---|
| `worker.js` | **SINGLE FILE** — full app embedded + Worker entry (449 KB) |
| `wrangler.toml` | Worker config |
| `merge.ps1` | Rebuild single `worker.js` from `../index.html` |
| `build-single.ps1` / `build.ps1` | older builders (unused) |

**Single-file:** deploy only `worker.js` + `wrangler.toml`. No `app.js` import.

## Full audit — bugs found & fixed

### Critical (Cloudflare-specific)
1. **No worker entry** — app was a raw `index.html`; fixed → `worker.js` serves it
2. **No CORS for browser→Worker** — direct client fetches to external APIs (OpenAI, Wikipedia, open-meteo, coingecko, ipify) will fail or hit provider CORS. **Fix:** route provider calls through Worker proxy (below).
3. **API keys in browser = leak** — if you later add keys, keep them in Worker secrets. Do NOT put them in `index.html`.
4. **localStorage/IndexedDB on Worker origin** — works fine (browser-side). No change needed.

### Important (code)
5. `init()` uses `ZSDB.zsChats.get` (async) — wrapped in `try` already; fails safe in private mode.
6. `renderPhstrip` / `libThumbs` — `alt` added for lazy images; history images already have alt.
7. `wordSwap`→class fix already applied (L737 + L2464) — no duplicate IDs on re-render.
8. Welcome `getEl` now uses `querySelector(".wordSwap")` — matches class-based DOM.
9. `srcdoc` double-escape removed in 2 spots.
10. `frameProgress` uses `.framebar` class.
11. `.libcell.html` → `.libcell-html` (CSS + JS) — no `<html>` false-positive.
12. Zoom removed — fluid layout.
13. AI prompts strengthened (`SITE_BUILD_TASK`, `SLIDES_TASK`, `appInstruction`) — require DOCTYPE/viewport/lang/`</html>`.
14. Output validation tightened — Win/Droid require `<html>`+`</html>`, game requires `<html>`+`<script>`+`<canvas>`.
15. `renderWinTools` fallback append if no `</body>`.
16. `meta` PWA/OG added; skip-link, `<main>`, `<nav>`, `aria-label`s, `<noscript>`.

### Remaining known limitations
- **Wikipedia / open-meteo / coingecko / ipify** — browser fetch works only if those APIs send `Access-Control-Allow-Origin`. They do for Wikipedia (`origin=*`) and open-meteo (permissive). CoinGecko/ipify may be blocked in some regions.
- **OpenAI-compatible providers** — most do NOT send CORS headers to browsers. Must use the Worker proxy below.
- **IndexedDB** — fine per browser; Workers do not touch it.
- **Provider modal / images** — generated images come from your provider; if provider blocks hotlink, download via Worker proxy.

## Worker proxy (for provider APIs)

Add to `worker.js` a `/api/proxy` route and set `S.proxyBase = "/api/proxy"` in the app so `pvFetch` goes through it. Add secrets:

```sh
wrangler secret put OPENAI_KEY
wrangler secret put HF_TOKEN
```

Example proxy in worker.js (add before 404):

```js
if (path === "/api/proxy" && request.method === "POST") {
  const body = await request.json();
  const { url, method = "POST", headers = {}, body: b } = body;
  const key = env.PROVIDER_KEY || env.OPENAI_KEY || "";
  const h = { ...headers, "content-type": headers["content-type"] || "application/json" };
  if (url.includes("openai.com") || url.includes("api.openai.com")) h["authorization"] = "Bearer " + key;
  if (url.includes("huggingface.co")) h["authorization"] = "Bearer " + (env.HF_TOKEN || key);
  const r = await fetch(url, { method, headers: h, body: b ? JSON.stringify(b) : undefined });
  const t = await r.text();
  return new Response(t, { status: r.status, headers: { "content-type": r.headers.get("content-type") || "application/json", "access-control-allow-origin": "*" } });
}
```

## Deploy steps

1. `cd deploy`
2. Install wrangler: `npm i -D wrangler` (needs Node.js)
3. `npx wrangler login`
4. `npx wrangler deploy`
5. Set secrets: `npx wrangler secret put PROVIDER_KEY`

URL: `https://zeroshift-studio.<your-subdomain>.workers.dev`

## Rebuild after editing index.html

```powershell
.\merge.ps1   # re-embeds index.html into single worker.js
npx wrangler deploy
```

## Quick local test

```powershell
cd deploy
npx wrangler dev
# opens http://localhost:8787
```
