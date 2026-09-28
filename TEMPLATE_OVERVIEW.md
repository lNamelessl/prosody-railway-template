# Prosody XMPP Chat Server — One-Click Railway Template

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/non6DC)

Your own XMPP chat server in one click. **Prosody** is the modern, standard XMPP
server: federated protocol, any client you like (Conversations, Gajim, Monal,
converse.js), persistent accounts and message archives. Zero deploy-form
inputs: the template provisions everything, creates your admin account at
first boot, and generates its admin password fresh per deployment.

## What you get

| Piece | Detail |
|---|---|
| `prosodyim/prosody:13.0` | the **official** Prosody image, pinned to the stable 13.0 branch |
| Web + websocket | `wss://YOUR-DOMAIN/xmpp-websocket` and `https://YOUR-DOMAIN/http-bind` behind Railway's TLS — no client TLS setup needed |
| XMPP client port | TCP proxy on 5222 for native clients (Conversations, Gajim) with STARTTLS |
| Persistence | volume on `/var/lib/prosody`: accounts, roster, message archive (MAM, 30-day expiry), STARTTLS certificate |
| Security posture | in-band registration **off** (admin-only server, no open relay); per-deploy random admin password |

## After deploying (2 minutes, no CLI needed beyond copying a password)

1. Open your service's **Variables** tab and copy the **`PASSWORD`** value —
   that is the password of your admin account.
2. Your JID is **admin@YOUR-DOMAIN** where YOUR-DOMAIN is the service
   domain shown on the service card (also the value of
   `PROSODY_VIRTUAL_HOSTS`).
3. Connect any XMPP client:
   - **Web/websocket clients:** WebSocket URL `wss://YOUR-DOMAIN/xmpp-websocket`
     (BOSH: `https://YOUR-DOMAIN/http-bind`).
   - **Conversations (Android) / Gajim (desktop):** JID
     `USER@YOUR-DOMAIN`, host = the **5222 TCP proxy** domain
     (`...proxy.rlwy.net`), port = the proxy port shown next to it. Prosody
     presents a self-signed certificate on this path (Railway's TLS covers the
     HTTPS domain); accept it once — the fingerprint is stable across restarts.

## Adding users

Registration is admin-only by design. Add users with the Railway CLI:

```bash
railway ssh --service prosody -- sh -c 'prosodyctl register USER "$PROSODY_VIRTUAL_HOSTS" "PASSWORD"'
```

## Federation (advanced)

Chatting with other XMPP servers requires a real domain you control,
`_xmpp-server._tcp` SRV records, and the 5269 s2s port. This template ships
single-domain; treat federation as a follow-up exercise on a custom domain.

# Deploy and Host

Deploy Prosody — the modern XMPP chat server — on Railway with one click. The
template runs the official `prosodyim/prosody:13.0` image in a single service
with a persistent volume for accounts and message archives. Your Railway
domain becomes the XMPP virtual host automatically
(`PROSODY_VIRTUAL_HOSTS=${{RAILWAY_PUBLIC_DOMAIN}}`), BOSH and WebSocket
endpoints are exposed through Railway's TLS, and a TCP proxy serves native
XMPP clients on port 5222. A small wrapper entrypoint adapts the
Railway-mounted (root-owned) volume to Prosody's needs, generates the vhost
certificate, and creates the `admin` account exactly once at first boot.

## About Hosting

Hosting your own XMPP server gives you a private, standards-based chat
back-end: no vendor lock-in, no per-seat pricing, works with every XMPP
client on every platform. On Railway it runs as a single ~512 MB service
with one volume (roughly $3–5/month). The template configures:

- `PROSODY_VIRTUAL_HOSTS=${{RAILWAY_PUBLIC_DOMAIN}}` — your Railway domain is the XMPP host
- `PROSODY_ADMINS=admin@${{RAILWAY_PUBLIC_DOMAIN}}` — admin JID
- `PASSWORD=${{secret(24, ...)}}` — fresh random admin password per deployment (Variables tab)
- `DOMAIN=${{RAILWAY_PUBLIC_DOMAIN}}` — used for the one-time first-boot admin registration
- HTTP domain on port 5280 (websocket `wss://…/xmpp-websocket`, BOSH
  `https://…/http-bind`), TCP proxy on 5222 (native clients, STARTTLS)
- Volume at `/var/lib/prosody` — accounts, roster, MAM archive (30-day
  expiry), and the self-signed vhost certificate

## Why Deploy

- **One click, zero forms** — no deploy-time inputs; admin credentials are
  generated per deployment and readable in the Variables tab.
- **Standard, not a walled garden** — XMPP means you can switch clients or
  self-host elsewhere any time; your accounts and archives live in an open
  format on your volume.
- **Official image, pinned** — `prosodyim/prosody:13.0` (the Prosody team's
  own image; the older `prosody/prosody` Docker Hub image is unmaintained).
- **Railway-ready image** — the upstream image refuses root-owned data
  volumes (upstream FIXME); this template's entrypoint wrapper fixes volume
  ownership, generates the STARTTLS certificate, and makes the first-boot
  admin registration one-shot so restarts never crash-loop.

## Common Use Cases

- Private team/family chat without handing conversations to a SaaS
- Lightweight notification/alert delivery to phones via XMPP bots
- A personal chat hub reachable from any device with Conversations, Gajim,
  Monal, or any web XMPP client
- Jitsi-style ecosystem familiarity — Prosody is the XMPP engine used across
  the Jabber network

## Dependencies for

None external — the template is fully self-contained. Prosody uses its
built-in internal storage on the attached volume; no database service is
provisioned or required.

### Deployment Dependencies

- A Railway account with the Hobby (or larger) plan (~$3–5/month for this
  single service + volume)
- Optional (advanced federation only): your own domain with
  `_xmpp-server._tcp` SRV records pointed at the server
