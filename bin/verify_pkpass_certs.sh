#!/bin/bash
# Verify Apple Wallet certificate setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/apple_wallet.yml"

# Parse YAML config file
get_config_value() {
  local key="$1"
  grep "^  ${key}:" "$CONFIG_FILE" | sed 's/^  [^:]*: *"\?\([^"]*\)"\?$/\1/' | tr -d '"'
}

# Load configuration
CERT_PATH="${SCRIPT_DIR}/../$(get_config_value 'certificate_path')"
KEY_PATH="${SCRIPT_DIR}/../$(get_config_value 'key_path')"
WWDR_CERT_PATH="${SCRIPT_DIR}/../$(get_config_value 'wwdr_certificate_path')"
PASS_TYPE_ID="$(get_config_value 'pass_type_identifier')"
TEAM_ID="$(get_config_value 'team_identifier')"

echo "=== Checking PassKit Certificate ==="

if [[ ! -f "$CERT_PATH" ]]; then
  echo "❌ Certificate file not found: $CERT_PATH"
  CERT_SUBJECT=""
else
  echo "File: $CERT_PATH"
  echo ""
  openssl x509 -in "$CERT_PATH" -noout -subject -issuer -dates -ext subjectAltName

  # Extract Pass Type ID and Team ID from certificate
  CERT_SUBJECT=$(openssl x509 -in "$CERT_PATH" -noout -subject)

  if [[ "$CERT_SUBJECT" == *"Pass Type ID:"* ]]; then
    CERT_PASS_TYPE=$(echo "$CERT_SUBJECT" | sed -n 's/.*Pass Type ID: \([^,]*\).*/\1/p')
    echo "Pass Type ID in cert: $CERT_PASS_TYPE"
  else
    echo "⚠️  WARNING: Pass Type ID not found in certificate"
  fi

  if [[ "$CERT_SUBJECT" == *"OU"*"="* ]]; then
    CERT_TEAM_ID=$(echo "$CERT_SUBJECT" | sed -n 's/.*OU[[:space:]]*=[[:space:]]*\([^,]*\).*/\1/p')
    echo "Team ID (OU) in cert: $CERT_TEAM_ID"
  else
    echo "⚠️  WARNING: Team ID (OU) not found in certificate"
  fi
fi

echo ""
echo "=== Checking WWDR Certificate ==="
echo "File: $WWDR_CERT_PATH"
echo ""
openssl x509 -in "$WWDR_CERT_PATH" -inform der -noout -subject -issuer -dates 2>/dev/null || \
  openssl x509 -in "$WWDR_CERT_PATH" -inform pem -noout -subject -issuer -dates

echo ""
echo "=== Expected Values ==="
echo "Pass Type ID in cert should match: $PASS_TYPE_ID"
echo "Team ID in cert should match: $TEAM_ID"
echo "WWDR issuer should be: CN=Apple Root CA - G3 Root CA, OU=Apple Certification Authority, O=Apple Inc., C=US"
echo "PassKit issuer should be: CN=Apple Worldwide Developer Relations G4..."
