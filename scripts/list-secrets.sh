#!/bin/bash

# Help function
show_help() {
    echo "Usage: $0 [-n NAMESPACE] [-t TYPE] [-o OUTPUT_FORMAT]"
    echo
    echo "List Kubernetes secrets with details"
    echo
    echo "Optional arguments:"
    echo "  -n NAMESPACE    Namespace to list secrets from (default: all namespaces)"
    echo "  -t TYPE        Filter by secret type (e.g., 'kubernetes.io/tls', 'Opaque')"
    echo "  -o FORMAT      Output format: text (default), wide, or json"
    echo "  -h            Show this help message"
    exit 1
}

# Parse arguments
while getopts "n:t:o:h" opt; do
    case $opt in
        n) NAMESPACE="$OPTARG";;
        t) TYPE="$OPTARG";;
        o) FORMAT="$OPTARG";;
        h) show_help;;
        \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
    esac
done

# Set default format if not specified
FORMAT=${FORMAT:-text}

# Build the kubectl command
if [ -n "$NAMESPACE" ]; then
    NS_FLAG="-n $NAMESPACE"
else
    NS_FLAG="--all-namespaces"
fi

# Function to get secret details in JSON format
get_secrets_json() {
    local ns_flag="$1"
    local type_selector=""
    
    if [ -n "$TYPE" ]; then
        type_selector="--field-selector type=$TYPE"
    fi
    
    kubectl get secrets $ns_flag $type_selector -o json | \
    jq '.items[] | {
        namespace: .metadata.namespace,
        name: .metadata.name,
        type: .type,
        keys: (.data | keys),
        created: .metadata.creationTimestamp,
        annotations: .metadata.annotations
    }'
}

# Function to format timestamp
format_timestamp() {
    local timestamp="$1"
    date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp"
}

case "$FORMAT" in
    json)
        get_secrets_json "$NS_FLAG"
        ;;
    wide)
        # Header
        printf "%-20s %-30s %-15s %-20s %-30s\n" "NAMESPACE" "NAME" "TYPE" "CREATED" "KEYS"
        echo "--------------------------------------------------------------------------------------------------------"
        
        # Get and format data
        kubectl get secrets $NS_FLAG -o json | \
        jq -r '.items[] | select((.type == env.TYPE) or (env.TYPE == "")) |
            [.metadata.namespace, .metadata.name, .type, .metadata.creationTimestamp, (.data | keys | join(","))] |
            @tsv' | \
        while IFS=$'\t' read -r namespace name type created keys; do
            created_fmt=$(format_timestamp "$created")
            printf "%-20s %-30s %-15s %-20s %-30s\n" "$namespace" "$name" "$type" "$created_fmt" "$keys"
        done
        ;;
    *)
        # Default text format
        if [ -n "$TYPE" ]; then
            kubectl get secrets $NS_FLAG --field-selector type=$TYPE
        else
            kubectl get secrets $NS_FLAG
        fi
        ;;
esac 