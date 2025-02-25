#!/bin/bash

# Help function
show_help() {
    echo "Usage: $0 -n NAMESPACE -s SECRET_NAME -f VALUES_FILE [-o OUTPUT_FILE]"
    echo
    echo "Seal a Kubernetes secret with multiple key-value pairs using kubeseal"
    echo
    echo "Required arguments:"
    echo "  -n NAMESPACE    Namespace for the secret"
    echo "  -s SECRET_NAME  Name of the secret"
    echo "  -f VALUES_FILE  File containing key-value pairs (one per line, format: KEY=VALUE)"
    echo
    echo "Optional arguments:"
    echo "  -o OUTPUT_FILE Output file (default: sealed-secret.yaml)"
    echo "  -h            Show this help message"
    exit 1
}

# Parse arguments
while getopts "n:s:f:o:h" opt; do
    case $opt in
    n) NAMESPACE="$OPTARG" ;;
    s) SECRET_NAME="$OPTARG" ;;
    f) VALUES_FILE="$OPTARG" ;;
    o) OUTPUT_FILE="$OPTARG" ;;
    h) show_help ;;
    \?)
        echo "Invalid option -$OPTARG" >&2
        exit 1
        ;;
    esac
done

# Validate required arguments
if [ -z "$NAMESPACE" ] || [ -z "$SECRET_NAME" ] || [ -z "$VALUES_FILE" ]; then
    echo "Error: Missing required arguments"
    show_help
fi

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: Values file '$VALUES_FILE' not found"
    exit 1
fi

# Set default output file if not specified
OUTPUT_FILE=${OUTPUT_FILE:-sealed-secret.yaml}

# Create temporary file for the secret
TEMP_FILE=$(mktemp)

# Start writing the secret YAML
cat >"$TEMP_FILE" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
type: Opaque
stringData:
EOF

# Add each key-value pair from the values file
while IFS='=' read -r key value; do
    # Skip empty lines and comments
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

    # Remove any leading/trailing whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)

    # Add the key-value pair to the YAML
    echo "  $key: $value" >>"$TEMP_FILE"
done <"$VALUES_FILE"

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
