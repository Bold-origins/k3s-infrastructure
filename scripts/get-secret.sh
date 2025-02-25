#!/bin/bash

# Help function
show_help() {
    echo "Usage: $0 -n NAMESPACE -s SECRET_NAME [-k KEY] [-o OUTPUT_FORMAT]"
    echo
    echo "Retrieve and decode Kubernetes secrets"
    echo
    echo "Required arguments:"
    echo "  -n NAMESPACE    Namespace of the secret"
    echo "  -s SECRET_NAME  Name of the secret"
    echo
    echo "Optional arguments:"
    echo "  -k KEY         Specific key to retrieve (if not specified, shows all keys)"
    echo "  -o FORMAT      Output format: text (default) or json"
    echo "  -h            Show this help message"
    exit 1
}

# Parse arguments
while getopts "n:s:k:o:h" opt; do
    case $opt in
    n) NAMESPACE="$OPTARG" ;;
    s) SECRET_NAME="$OPTARG" ;;
    k) KEY="$OPTARG" ;;
    o) FORMAT="$OPTARG" ;;
    h) show_help ;;
    \?)
        echo "Invalid option -$OPTARG" >&2
        exit 1
        ;;
    esac
done

# Validate required arguments
if [ -z "$NAMESPACE" ] || [ -z "$SECRET_NAME" ]; then
    echo "Error: Missing required arguments"
    show_help
fi

# Set default format if not specified
FORMAT=${FORMAT:-text}

# Check if secret exists
if ! kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" &>/dev/null; then
    echo "Error: Secret '$SECRET_NAME' not found in namespace '$NAMESPACE'"
    exit 1
fi

# Function to decode base64 value
decode_base64() {
    echo "$1" | base64 -d
}

# If specific key is provided
if [ -n "$KEY" ]; then
    # Get specific key
    VALUE=$(kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o jsonpath="{.data.$KEY}" 2>/dev/null)
    if [ -z "$VALUE" ]; then
        echo "Error: Key '$KEY' not found in secret"
        exit 1
    fi

    if [ "$FORMAT" = "json" ]; then
        echo "{"
        echo "  \"$KEY\": \"$(decode_base64 "$VALUE")\""
        echo "}"
    else
        echo "$KEY=$(decode_base64 "$VALUE")"
    fi
else
    # Get all keys and values
    if [ "$FORMAT" = "json" ]; then
        echo "{"
        kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o json |
            jq -r '.data | to_entries | .[] | "\(.key)": "\(.value | @base64d)"' |
            sed 's/^/  /'
        echo "}"
    else
        kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o json |
            jq -r '.data | to_entries | .[] | "\(.key)=\(.value | @base64d)"'
    fi
fi
