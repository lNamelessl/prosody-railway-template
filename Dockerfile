# Prosody XMPP server on Railway (template image).
#
# Pinned to the OFFICIAL prosodyim/prosody:13.0 image (the older
# prosody/prosody image is unmaintained; Prosody's own docs steer users to
# prosodyim/prosody). The 13.0 tag tracks the stable 13.0 release branch and
# is rebuilt daily upstream — a versioned branch pin keeps this template
# reproducible.
#
# Why a derived image (2 upstream-verified reasons):
#   1. Railway volumes mount root-owned. The official entrypoint adapts the
#      prosody user's UID to the data-dir owner (`usermod -u "$owner" prosody`)
#      and upstream flags the root-owned case itself:
#      `# FIXME this fails if owned by root` -> container fails to start.
#      Our wrapper chowns the volumes to the prosody user BEFORE the official
#      entrypoint runs, which makes that usermod branch a no-op.
#   2. Zero-credential onboarding: the official entrypoint registers a first
#      user when LOCAL/DOMAIN/PASSWORD are set — but it runs under `set -e` on
#      EVERY boot, and re-registering an existing user aborts the script
#      (crash loop). Our wrapper unsets that trio once the admin account file
#      exists, so registration fires exactly once (first boot only).
# It also generates a self-signed cert for the vhost on first boot so XMPP
# clients on the 5222 TCP proxy can negotiate STARTTLS (persisted in the
# /etc/prosody/certs volume so the fingerprint stays stable across restarts).
FROM prosodyim/prosody:13.0

# Literal config baked into the image on purpose (NOT template variables ->
# zero deploy-form prompts):
#   - websocket,bosh: BOTH are commented out in the image's default
#     modules_enabled; PROSODY_ENABLE_MODULES appends via
#     `modules_enabled:append(...)` so all defaults stay intact.
#     smacks (stream resumption) is already on by default.
#   - PROSODY_ARCHIVE_EXPIRY_DAYS > 0 auto-enables mod_mam (message archive),
#     giving provable archive persistence on the data volume.
#   - LOCAL=admin: first-boot admin username consumed by the official
#     entrypoint's LOCAL/DOMAIN/PASSWORD auto-register flow (DOMAIN and
#     PASSWORD come from Railway service variables).
ENV PROSODY_ENABLE_MODULES=websocket,bosh \
    PROSODY_ARCHIVE_EXPIRY_DAYS=30 \
    LOCAL=admin

COPY conf.d/railway.cfg.lua /etc/prosody/conf.d/railway.cfg.lua
COPY railway-entrypoint.sh /railway-entrypoint.sh
RUN chmod +x /railway-entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/railway-entrypoint.sh"]
CMD ["prosody", "-F"]
