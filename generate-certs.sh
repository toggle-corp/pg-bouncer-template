#!/usr/bin/env bash
# Generate a self-signed TLS certificate for PostgreSQL SSL connections.
# Reference: https://www.postgresql.org/docs/14/ssl-tcp.html#SSL-CERTIFICATE-CREATION
set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIRECTORY="$BASEDIR/certs"
CERT_FILE="$CERT_DIRECTORY/proxy-cert.pem"
KEY_FILE="$CERT_DIRECTORY/proxy-key.pem"

# ── Output helpers ────────────────────────────────────────────────────────────
_has_color() { [[ -t 2 ]]; }

echo_info()    { _has_color && echo -e "\033[0;36m$*\033[0m" >&2    || echo "$*" >&2; }
echo_success() { _has_color && echo -e "\033[0;32m$*\033[0m" >&2    || echo "$*" >&2; }
echo_warn()    { _has_color && echo -e "\033[0;33m$*\033[0m" >&2    || echo "$*" >&2; }
echo_error()   { _has_color && echo -e "\033[0;31m$*\033[0m" >&2    || echo "$*" >&2; }
echo_bold()    { _has_color && echo -e "\033[1m$*\033[0m" >&2       || echo "$*" >&2; }
echo_value()   { _has_color && echo -e "   \033[0;36m$1\033[0m: $2" >&2 || echo "   $1: $2" >&2; }

# ── Check for existing certificates ──────────────────────────────────────────
check_existing() {
    if [[ -f "$CERT_FILE" && -f "$KEY_FILE" ]]; then
        echo_success "✅ Certificates already exist:"
        echo_info    "   $CERT_FILE"
        echo_info    "   $KEY_FILE"
        echo_warn    "⏭️  Skipping generation."
        exit 0
    elif [[ -f "$CERT_FILE" || -f "$KEY_FILE" ]]; then
        echo_error "❌ Incomplete certificate pair — only one file exists:"
        if [[ -f "$CERT_FILE" ]]; then
            echo_success "   [found]   $CERT_FILE"
        else
            echo_error   "   [missing] $CERT_FILE"
        fi
        if [[ -f "$KEY_FILE" ]]; then
            echo_success "   [found]   $KEY_FILE"
        else
            echo_error   "   [missing] $KEY_FILE"
        fi
        exit 1
    fi
}

# ── Prompt for certificate CN ─────────────────────────────────────────────────
get_certificate_cn() {
    local public_ip fqdn cn_input

    public_ip=$(curl -sf --max-time 5 https://api.ipify.org \
        || curl -sf --max-time 5 https://ifconfig.me \
        || echo "unavailable")
    fqdn=$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo "unavailable")

    echo >&2
    echo_bold  "🌐 Server Info:"
    echo_value "Public IP" "$public_ip"
    echo_value "Hostname"  "$fqdn"
    echo >&2
    echo_warn  "   💡 Use a domain name (e.g. myserver.example.com) rather than an IP"
    echo_warn  "      address — certificates tied to domains are easier to renew and trust."
    echo >&2
    read -r -e -p "$(echo -e "   \033[1m🔑 Enter domain or IP for certificate CN:\033[0m ")" cn_input </dev/tty

    if [[ -z "$cn_input" ]]; then
        echo_error "❌ Error: a domain or IP is required."
        return 1
    fi

    echo "$cn_input"
}

# ── Prompt for expiry days ────────────────────────────────────────────────────
get_expire_days() {
    local days_input
    echo >&2
    read -r -e -i "3650" -p "$(echo -e "   \033[1m📅 Enter certificate validity in days:\033[0m ")" days_input </dev/tty

    if ! [[ "$days_input" =~ ^[0-9]+$ ]] || [[ "$days_input" -lt 1 ]]; then
        echo_error "❌ Error: validity must be a positive integer."
        return 1
    fi

    echo "$days_input"
}

# ── Generate the certificate ──────────────────────────────────────────────────
generate_certificate() {
    local cn="$1"
    local days="$2"
    local years confirm

    years=$(echo "scale=1; $days / 365" | bc)

    # Detect if CN is an IP address or a domain
    if [[ "$cn" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        san="IP:$cn"
    else
        san="DNS:$cn"
    fi

    echo >&2
    echo_bold  "🔐 Generating self-signed certificate..."
    echo_value "CN"        "$cn"
    echo_value "SAN"       "$san"
    echo_value "Valid for" "$days days (~${years} years)"
    echo >&2

    read -r -e -p "$(echo -e "   \033[1m⚠️  Proceed with generation? [y/N]:\033[0m ")" confirm </dev/tty
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo_warn "⏭️  Aborted."
        exit 0
    fi

    echo >&2
    mkdir -p "$CERT_DIRECTORY"
    set -x
    openssl req \
        -new -x509 \
        -nodes -text \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -days "$days" \
        -subj "/CN=$cn" \
        -addext "subjectAltName=$san"
    { set +x; } 2>/dev/null
    chmod 600 "$CERT_FILE" "$KEY_FILE"

    echo >&2
    echo_success "✅ Certificate generated successfully!"
    echo_value   "Cert" "$CERT_FILE"
    echo_value   "Key"  "$KEY_FILE"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    echo >&2
    echo_bold "🛡️  TLS Certificate Generator"
    echo_info "────────────────────────────────────"

    check_existing

    local cn days
    cn=$(get_certificate_cn)
    days=$(get_expire_days)
    generate_certificate "$cn" "$days"
}

main
