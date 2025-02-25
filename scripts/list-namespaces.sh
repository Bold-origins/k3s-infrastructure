#!/bin/bash

# Help function
show_help() {
    echo "Usage: $0 [-o OUTPUT_FORMAT]"
    echo
    echo "List Kubernetes namespaces with their purposes"
    echo
    echo "Optional arguments:"
    echo "  -o FORMAT      Output format: text (default) or json"
    echo "  -h            Show this help message"
    exit 1
}

# Parse arguments
while getopts "o:h" opt; do
    case $opt in
    o) FORMAT="$OPTARG" ;;
    h) show_help ;;
    \?)
        echo "Invalid option -$OPTARG" >&2
        exit 1
        ;;
    esac
done

# Set default format if not specified
FORMAT=${FORMAT:-text}

# Define namespace purposes
declare -A NS_PURPOSES=(
    ["infra"]="Core infrastructure components (cert-manager, ingress-nginx, sealed-secrets)"
    ["observability"]="Monitoring and logging (Prometheus, Grafana, Loki, Tempo)"
    ["security"]="Security tools (Vault, Falco, Gatekeeper)"
    ["storage"]="Storage solutions (MinIO)"
    ["flux-system"]="Flux GitOps components"
)

case "$FORMAT" in
json)
    echo "{"
    echo "  \"namespaces\": ["
    first=true
    kubectl get ns -o json | jq -r '.items[] | .metadata.name' | while read -r ns; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        purpose="${NS_PURPOSES[$ns]:-"User namespace"}"
        echo "    {"
        echo "      \"name\": \"$ns\","
        echo "      \"purpose\": \"$purpose\","
        echo "      \"status\": \"$(kubectl get ns "$ns" -o jsonpath='{.status.phase}')\""
        echo -n "    }"
    done
    echo
    echo "  ]"
    echo "}"
    ;;
*)
    # Print header
    printf "%-20s %-50s %-10s\n" "NAMESPACE" "PURPOSE" "STATUS"
    echo "--------------------------------------------------------------------------------"

    # List all namespaces with their purposes
    kubectl get ns -o json | jq -r '.items[] | [.metadata.name, .status.phase] | @tsv' |
        while IFS=$'\t' read -r ns status; do
            purpose="${NS_PURPOSES[$ns]:-"User namespace"}"
            printf "%-20s %-50s %-10s\n" "$ns" "$purpose" "$status"
        done
    ;;
esac
