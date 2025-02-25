#!/bin/bash

# Help function
show_help() {
    echo "Usage: $0 -n NAMESPACE -s SECRET_NAME -k KEY -v VALUE [-f OUTPUT_FILE]"
    echo
    echo "Seal a Kubernetes secret using kubeseal"
    echo
    echo "Required arguments:"
    echo "  -n NAMESPACE    Namespace for the secret"
    echo "  -s SECRET_NAME  Name of the secret"
    echo "  -k KEY         Key in the secret"
    echo "  -v VALUE       Value for the key"
    echo
    echo "Optional arguments:"
    echo "  -f OUTPUT_FILE Output file (default: sealed-secret.yaml)"
    echo "  -h            Show this help message"
    exit 1
}

# Parse arguments
while getopts "n:s:k:v:f:h" opt; do
    case $opt in
    n) NAMESPACE="$OPTARG" ;;
    s) SECRET_NAME="$OPTARG" ;;
    k) KEY="$OPTARG" ;;
    v) VALUE="$OPTARG" ;;
    f) OUTPUT_FILE="$OPTARG" ;;
    h) show_help ;;
    \?)
        echo "Invalid option -$OPTARG" >&2
        exit 1
        ;;
    esac
done

# Validate required arguments
if [ -z "$NAMESPACE" ] || [ -z "$SECRET_NAME" ] || [ -z "$KEY" ] || [ -z "$VALUE" ]; then
    echo "Error: Missing required arguments"
    show_help
fi

# Set default output file if not specified
OUTPUT_FILE=${OUTPUT_FILE:-sealed-secret.yaml}

# Create temporary file for the secret
TEMP_FILE=$(mktemp)

# Create the secret YAML
cat >"$TEMP_FILE" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
type: Opaque
stringData:
  $KEY: $VALUE
EOF

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Seal the secret
echo "Sealing secret '$SECRET_NAME' in namespace '$NAMESPACE'..."
if ! kubeseal --format yaml --controller-namespace=infra --controller-name=sealed-secrets <"$TEMP_FILE" >"$OUTPUT_FILE"; then
    echo "Error: Failed to seal secret"
    rm "$TEMP_FILE"
    exit 1
fi

# Clean up
rm "$TEMP_FILE"

echo "Secret sealed successfully and saved to $OUTPUT_FILE"
