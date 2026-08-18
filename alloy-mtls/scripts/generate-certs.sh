#!/bin/sh
set -eu

if ! command -v openssl >/dev/null 2>&1; then
  echo "error: openssl is required to generate the demo certificates" >&2
  exit 1
fi

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
cert_dir=${CERT_DIR:-"$script_dir/../certs"}

# Do not silently replace an identity that may be in use by a running stack.
if [ -e "$cert_dir/ca.crt" ]; then
  echo "error: $cert_dir already contains certificates; remove it before regenerating" >&2
  exit 1
fi

umask 077
mkdir -p "$cert_dir"

server_ext="$cert_dir/server.ext"
client_ext="$cert_dir/client.ext"
trap 'rm -f "$server_ext" "$client_ext"' EXIT HUP INT TERM

# Generate the trusted root CA used by central Alloy and the authorized edge.
openssl genrsa -out "$cert_dir/ca.key" 2048
openssl req -x509 -new -nodes -key "$cert_dir/ca.key" -sha256 -days 3650 \
  -subj "/CN=alloy-mtls-demo-ca" -out "$cert_dir/ca.crt"

# Generate the central Alloy TLS server certificate, signed by the trusted CA.
openssl genrsa -out "$cert_dir/central-server.key" 2048
openssl req -new -key "$cert_dir/central-server.key" \
  -subj "/CN=central-alloy" -out "$cert_dir/central-server.csr"
printf 'subjectAltName=DNS:central-alloy,DNS:localhost\nextendedKeyUsage=serverAuth\n' >"$server_ext"
openssl x509 -req -in "$cert_dir/central-server.csr" -CA "$cert_dir/ca.crt" -CAkey "$cert_dir/ca.key" \
  -CAcreateserial -out "$cert_dir/central-server.crt" -days 3650 -sha256 -extfile "$server_ext"

# Generate the authorized edge Alloy TLS client certificate, signed by the trusted CA.
openssl genrsa -out "$cert_dir/edge-client.key" 2048
openssl req -new -key "$cert_dir/edge-client.key" \
  -subj "/CN=edge-alloy" -out "$cert_dir/edge-client.csr"
printf 'extendedKeyUsage=clientAuth\n' >"$client_ext"
openssl x509 -req -in "$cert_dir/edge-client.csr" -CA "$cert_dir/ca.crt" -CAkey "$cert_dir/ca.key" \
  -CAcreateserial -out "$cert_dir/edge-client.crt" -days 3650 -sha256 -extfile "$client_ext"

# Generate an untrusted root CA that central Alloy intentionally does not trust.
openssl genrsa -out "$cert_dir/untrusted-ca.key" 2048
openssl req -x509 -new -nodes -key "$cert_dir/untrusted-ca.key" -sha256 -days 3650 \
  -subj "/CN=alloy-mtls-untrusted-demo-ca" -out "$cert_dir/untrusted-ca.crt"

# Generate the unauthorized edge client certificate, signed by the untrusted CA.
openssl genrsa -out "$cert_dir/untrusted-edge-client.key" 2048
openssl req -new -key "$cert_dir/untrusted-edge-client.key" \
  -subj "/CN=unauthorized-edge-alloy" -out "$cert_dir/untrusted-edge-client.csr"
openssl x509 -req -in "$cert_dir/untrusted-edge-client.csr" \
  -CA "$cert_dir/untrusted-ca.crt" -CAkey "$cert_dir/untrusted-ca.key" \
  -CAcreateserial -out "$cert_dir/untrusted-edge-client.crt" -days 3650 -sha256 -extfile "$client_ext"

rm -f "$cert_dir/central-server.csr" "$cert_dir/edge-client.csr" \
  "$cert_dir/untrusted-edge-client.csr" "$cert_dir/ca.srl" "$cert_dir/untrusted-ca.srl"
echo "Generated demo certificates in $cert_dir"
