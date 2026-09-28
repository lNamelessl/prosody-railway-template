# Prosody XMPP Server on Railway

One-click deploy of **Prosody** — the modern, standard XMPP chat server — on
Railway. Your own chat server: federated protocol, any XMPP client
(Conversations, Gajim, Monal, Snikket, converse.js), persistent accounts and
message archives.

Deploy:

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.app/new?github_url=https://github.com/lNamelessl/prosody-railway-template)

(Published template URL: https://railway.com/deploy/prosody-template)

## What you get

| Piece | Detail |
|---|---|
| `prosodyim/prosody:13.0` | the **official** Prosody image (the older `prosody/prosody` image is unmaintained), pinned to the stable 13.0 branch |
| HTTP service domain | serves `wss://<your-domain>/xmpp-websocket` (XMPP over WebSocket) and `https://<your-domain>/http-bind` (BOSH) behind Railway's TLS |
| TCP proxy on 5222 | standard XMPP client connections (Conversations, Gajim, …) with STARTTLS |
| TCP proxy on 5269 | server-to-server (s2s) federation port — see "Federation (advanced)" |
| Volume `/var/lib/prosody` | accounts, roster, message archives (MAM) — survive restarts |
| Volume `/etc/prosody/certs` | self-signed STARTTLS certificate — stable fingerprint across restarts |

## Zero-credential onboarding

The template needs **no deploy-form input**. On first boot:

- the virtual host is set to your Railway domain (`<something>.up.railway.app`)
- an admin account **`admin@<your-domain>`** is created automatically
- the admin password is the per-deploy generated **`PASSWORD`** variable —
  open your service's **Variables** tab and copy it

Your JID: `admin@<your-domain>` · password: value of `PASSWORD` in the Variables tab.

## Adding users (admin-only by design)

In-band registration is **disabled** (no open relay, no spam signups). Add
users from your machine with the Railway CLI:

```bash
railway ssh --service Prosody -- prosodyctl register <username> "$PROSODY_VIRTUAL_HOSTS" '<password>'
```

(`$PROSODY_VIRTUAL_HOSTS` is already set inside the container to your domain.)
Users then log in with JID `<username>@<your-domain>`.

## Connecting clients

Your vhost/domain is `<your-domain>` (the Railway service domain, shown on the
service card and in `PROSODY_VIRTUAL_HOSTS`).

### Web / websocket (cleanest — valid TLS)

Any XMPP-over-WebSocket client can use:

- **WebSocket URL:** `wss://<your-domain>/xmpp-websocket`
- **BOSH URL:** `https://<your-domain>/http-bind`

### Conversations (Android)

1. Add account with JID `<user>@<your-domain>` and the password.
2. If it doesn't connect automatically, edit the account → **Host**: the
   5222 **TCP proxy** domain (e.g. `xxxx.proxy.rlwy.net`), **Port**: the
   proxy port shown next to it.
3. Prosody presents a self-signed certificate (Railway's TLS only covers the
   HTTPS domain) — accept it when prompted. This is the standard trade-off for
   proxied XMPP c2s; the fingerprint is stable across restarts.

### Gajim (desktop)

1. Add account `<user>@<your-domain>`.
2. In the account settings set **Custom host/port** to the 5222 TCP proxy
   domain and port.
3. Accept the self-signed certificate when Gajim prompts.

## Administration cheat-sheet

```bash
railway ssh --service Prosody -- prosodyctl register <user> "$PROSODY_VIRTUAL_HOSTS" '<pass>'  # add user
railway ssh --service Prosody -- prosodyctl shell                                              # admin shell
railway logs -d -s Prosody                                                                     # runtime logs
```

Storage is Prosody's built-in internal store on the persistent volume.
Message archiving (MAM) is enabled with a 30-day archive expiry
(`PROSODY_ARCHIVE_EXPIRY_DAYS=30`).

## Federation (advanced)

Federation (chatting with users on other XMPP servers) needs three things this
template ships but does **not** configure for you:

1. a **real domain you control** pointing at the server (Railway-assigned
   domains cannot receive SRV records),
2. `_xmpp-server._tcp.<your-domain>` SRV DNS records,
3. the 5269 TCP proxy mapped (already created).

Until then the server is single-domain. We recommend treating federation as a
follow-up exercise, not a first-day feature.

## Why the custom entrypoint?

Railway volumes mount root-owned, and the official image refuses that state
(upstream: `# FIXME this fails if owned by root` in its entrypoint). This
repo's image wraps the official entrypoint to `chown` the volumes to the
`prosody` user first, generate the self-signed vhost cert, and make the
first-boot admin registration one-shot (the upstream auto-register would
otherwise re-run on every boot and abort under `set -e`).

## References

- Prosody Docker docs: https://prosody.im/doc/docker
- Prosody WebSocket docs: https://prosody.im/doc/websocket
- Clients: https://prosody.im/download/clients — Conversations (Android),
  Gajim (desktop), converse.js (web)
