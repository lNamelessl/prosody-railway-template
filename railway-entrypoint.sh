#!/bin/bash
# Railway wrapper for the official prosodyim/prosody entrypoint.
# Runs as root (the official entrypoint requires root too: usermod / chown /
# prosodyctl register), then execs it unchanged.
set -e

VHOST="${PROSODY_VIRTUAL_HOSTS:-${DOMAIN:-}}"
PROSODY_UID="$(id -u prosody)"

# --- 1. Fix root-owned volumes ------------------------------------------------
# Railway volumes mount root-owned. The official entrypoint runs
#   usermod -u "$data_dir_owner" prosody
# when the data-dir owner differs from the prosody user, which upstream marks
# `# FIXME this fails if owned by root`. Chowning the data dir to the prosody
# user makes that branch a no-op. Only chown when needed (fast on restarts).
DATA_OWNER="$(stat -c %u /var/lib/prosody/ 2>/dev/null || echo '?')"
if [[ "$DATA_OWNER" != "$PROSODY_UID" ]]; then
    echo "[railway-entrypoint] chown /var/lib/prosody ($DATA_OWNER -> $PROSODY_UID)"
    chown -R prosody:prosody /var/lib/prosody
fi

# --- 2. First-boot self-signed cert for the vhost ------------------------------
# Needed for STARTTLS on the 5222 TCP proxy (c2s_requires_encryption=true by
# default). Persisted in the /etc/prosody/certs volume so clients that accept
# the certificate once keep a stable fingerprint across restarts.
CERT_DIR="/etc/prosody/certs"
if [[ -n "$VHOST" ]]; then
    mkdir -p "$CERT_DIR"
    if [[ ! -f "$CERT_DIR/$VHOST.crt" ]]; then
        echo "[railway-entrypoint] generating self-signed cert for $VHOST"
        prosodyctl --root cert generate "$VHOST" >/dev/null 2>&1 \
            || openssl req -new -x509 -days 3650 -nodes \
                 -subj "/CN=$VHOST" -addext "subjectAltName=DNS:$VHOST" \
                 -keyout "$CERT_DIR/$VHOST.key" -out "$CERT_DIR/$VHOST.crt" \
                 >/dev/null 2>&1
    fi
    CERT_OWNER="$(stat -c %u "$CERT_DIR" 2>/dev/null || echo '?')"
    if [[ "$CERT_OWNER" != "$PROSODY_UID" ]]; then
        chown -R prosody:prosody "$CERT_DIR"
    fi
fi

# --- 3. One-time admin registration --------------------------------------------
# The official entrypoint runs `prosodyctl register "$LOCAL" "$DOMAIN" "$PASSWORD"`
# on EVERY boot under `set -e`; re-registering an existing user aborts the
# script -> crash loop. Unset the trio once the account file exists so the
# official register block only fires on genuinely first boot.
if [[ -n "$LOCAL" && -n "$DOMAIN" && -n "$PASSWORD" ]]; then
    if [[ -f "/var/lib/prosody/$DOMAIN/accounts/$LOCAL.dat" ]]; then
        echo "[railway-entrypoint] admin account exists, skipping auto-register"
        unset LOCAL PASSWORD DOMAIN
    fi
fi

exec /entrypoint.sh "$@"
