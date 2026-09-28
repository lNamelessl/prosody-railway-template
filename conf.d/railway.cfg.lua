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

-- Security posture: in-band registration stays OFF (admin-only server, no
-- open relay, no spam signups). The first admin account is created at first
-- boot from the LOCAL/DOMAIN/PASSWORD variables; extra users are added by the
-- admin via `prosodyctl register <user> <domain> <password>` (see README).
allow_registration = false
