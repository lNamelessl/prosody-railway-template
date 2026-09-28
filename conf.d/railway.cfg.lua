-- Railway template additions (loaded via the PROSODY_EXTRA_CONFIG default
-- include of /etc/prosody/conf.d/*.cfg.lua).
--
-- Railway's edge terminates TLS for your domain and forwards plain HTTP to
-- Prosody on 5280. Without these options Prosody would consider BOSH and
-- WebSocket sessions insecure (it only sees plain HTTP), and clients would
-- refuse to negotiate sessions. Marking the endpoints "secure" tells Prosody
-- the TLS was handled by the proxy in front of it.
consider_bosh_secure = true
consider_websocket_secure = true

-- Vanilla Prosody binds its HTTP service to localhost only
-- (http_interfaces default { "127.0.0.1", "::1" }) — Railway's proxy could
-- never reach it (502). Open the BOSH/WebSocket listener to all interfaces.
http_interfaces = { "*" }

-- Archive ALL chat messages by default (Prosody's stock default is
-- "roster" only, which silently drops history between users who never
-- added each other to their rosters). Personal-server default: keep
-- everything; expired entries are pruned by PROSODY_ARCHIVE_EXPIRY_DAYS.
default_archive_policy = true

-- Railway attaches ONE volume per service, so the STARTTLS certificates live
-- inside the persistent data volume (/var/lib/prosody) rather than the
-- default /etc/prosody/certs. Keeps the self-signed cert (and its
-- fingerprint, which clients "accept once") stable across redeploys.
certificates = "/var/lib/prosody/certs"

-- Security posture: in-band registration stays OFF (admin-only server, no
-- open relay, no spam signups). The first admin account is created at first
-- boot from the LOCAL/DOMAIN/PASSWORD variables; extra users are added by the
-- admin via `prosodyctl register <user> <domain> <password>` (see README).
allow_registration = false
