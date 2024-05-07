#!/bin/bash -e

# https://www.postgresql.org/docs/14/ssl-tcp.html#SSL-CERTIFICATE-CREATION
BASEDIR="$(dirname "${BASH_SOURCE[0]}")"

CERT_DIRECTORY="$BASEDIR/certs"
CERT_FILE="$CERT_DIRECTORY/proxy-cert.pem"
KEY_FILE="$CERT_DIRECTORY/proxy-key.pem"
VM_PUBLIC_IP=$(curl ifconfig.me)

set -x
mkdir -p $CERT_DIRECTORY


openssl req \
    -new -x509 \
    -nodes -text \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days 3650 \
    -subj "/CN=$VM_PUBLIC_IP" \
    -addext subjectAltName="DNS:localhost,IP:127.0.0.1,IP:$VM_PUBLIC_IP"

chmod og-rwx "$CERT_FILE"
chmod og-rwx "$KEY_FILE"
