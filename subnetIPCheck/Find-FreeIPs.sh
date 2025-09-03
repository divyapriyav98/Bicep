#!/bin/bash

VNET_RG=""
VNET_NAME=""
SUBNET_NAME=""
SUBNET_ID=""
 
# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --VNET_RG)
            VNET_RG="$2"
            shift 2
            ;;
        --VNET_NAME)
            VNET_NAME="$2"
            shift 2
            ;;
        --SUBNET_NAME)
            SUBNET_NAME="$2"
            shift 2
            ;;
        --SUBNET_ID)
            SUBNET_ID="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 --vnet-rg <name> --vnet-name <name> --subnet-name <name> --subnet-id <id>"
            echo "Required Options:"
            echo "  --vnet-rg <name>        Resource group name"
            echo "  --vnet-name <name>      Virtual network name"
            echo "  --subnet-name <name>    Subnet name"
            echo "  --subnet-id <id>        Full subnet resource ID"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done
 
# Validate that all required parameters are provided
if [ -z "$VNET_RG" ] || [ -z "$VNET_NAME" ] || [ -z "$SUBNET_NAME" ] || [ -z "$SUBNET_ID" ]; then
    echo "Error: All parameters are required"
    echo "Usage: $0 --vnet-rg <name> --vnet-name <name> --subnet-name <name> --subnet-id <id>"
    echo "Use -h or --help for more information"
    exit 1
fi
 
# Function to convert IP to integer
ip_to_int() {
    local ip=$1
    local a b c d
    IFS=. read -r a b c d <<< "$ip"
    echo $((a * 256**3 + b * 256**2 + c * 256 + d))
}
 
# Function to convert integer to IP
int_to_ip() {
    local int=$1
    echo "$(( (int >> 24) & 255 )).$(( (int >> 16) & 255 )).$(( (int >> 8) & 255 )).$(( int & 255 ))"
}
 
 
# Get available IPs directly from Azure CLI
echo "Getting available IPs from Azure..."
AVAILABLE_IPS_RAW=$(az network vnet subnet list-available-ips \
    --resource-group "$VNET_RG" \
    --vnet-name "$VNET_NAME" \
    --name "$SUBNET_NAME" \
    --query "[0:10]" \
    --output tsv 2>/dev/null)
 
if [ $? -ne 0 ] || [ -z "$AVAILABLE_IPS_RAW" ]; then
    echo "Error: Failed to get available IPs from subnet"
    exit 1
fi
 
# Convert to array
AVAILABLE_IPS=()
while IFS= read -r ip; do
    if [ -n "$ip" ]; then
        AVAILABLE_IPS+=("$ip")
    fi
done <<< "$AVAILABLE_IPS_RAW"
 
echo "Available IPs: ${AVAILABLE_IPS[*]}"
 
# Prepare output
if [ ${#AVAILABLE_IPS[@]} -eq 0 ]; then
    echo "WARNING: No available IP addresses found in subnet"
    RESULT_IPS=()
else
    echo "Found ${#AVAILABLE_IPS[@]} available IP addresses"
    # Return the first 2 available IPs
    RESULT_IPS=("${AVAILABLE_IPS[@]:0:2}")
fi
 
# Set output path if not set
if [ -z "$AZ_SCRIPTS_OUTPUT_PATH" ]; then
    AZ_SCRIPTS_OUTPUT_PATH="./output.json"
fi
 
# Create JSON output
if [ ${#RESULT_IPS[@]} -eq 0 ]; then
    JSON_OUTPUT='{"IP1": null, "IP2": null, "UsedIPs": []}'
else
    # Get first two IPs or null if not available
    IP1="${RESULT_IPS[0]:-null}"
    IP2="${RESULT_IPS[1]:-null}"
   
    # Format IP1 and IP2 for JSON
    if [ "$IP1" = "null" ]; then
        JSON_IP1="null"
    else
        JSON_IP1="\"$IP1\""
    fi
   
    if [ "$IP2" = "null" ]; then
        JSON_IP2="null"
    else
        JSON_IP2="\"$IP2\""
    fi
   
    JSON_OUTPUT="{\"IP1\": $JSON_IP1, \"IP2\": $JSON_IP2, \"UsedIPs\": []}"
fi
 
echo "$JSON_OUTPUT" > "$AZ_SCRIPTS_OUTPUT_PATH"
echo "Output written to: $AZ_SCRIPTS_OUTPUT_PATH"
echo "JSON Output: $JSON_OUTPUT"
 
if [ ${#AVAILABLE_IPS[@]} -gt 0 ]; then
    echo "Available IPs (first 2): ${RESULT_IPS[*]}"
    echo "All available IPs: ${AVAILABLE_IPS[*]}"
else
    echo "No available IPs found!"
fi
 
 
