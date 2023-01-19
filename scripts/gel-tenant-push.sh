#!/bin/sh

# This script sends some test log lines to a Grafana Enterprise Logs instance.

set -e   # Exit on error

function usage() {
    echo "Logs some lines to a Grafana Enterprise Logs instance."
    echo "Usage: $0 [args]"
    echo ""
    echo "Arguments:"
    echo -e "  -a, --api-url <url> \t\tBase URL for the GEL API, e.g. http://127.0.0.1:3100"
    echo -e "  -u, --user <id> \t\tThe ID of the Tenant in GEL"
    echo -e "  -t, --token <token> \t\tToken which has permission to write logs"
    echo -e "  -h, --help \t\t\tShow this help"
    echo ""
    echo "Example:"
    echo "$0 -a http://loki.company:3100 -u healingcrystals -t xxxxAAAXXXBBBBB=="
    echo ""
    # exit 1
}


# If curl is not installed, bail out.
if ! command -v curl &> /dev/null
then
    echo "This script needs curl to run! Bailing out."
    exit 1
fi


# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -a|--api-url)
            gel_api_base_url="$2"
            shift # past argument
            shift # past value
            ;;
        -u|--user)
            gel_tenant_id="$2"
            shift # past argument
            shift # past value
            ;;
        -t|--token)
            gel_push_token="$2"
            shift # past argument
            shift # past value
            ;;
        -h|--help)
            usage
            exit 1
            ;;
        *)
            echo "Unknown argument: $key"
            usage
            exit 1
            ;;
    esac
done


# If any of the required arguments are missing, bail out.
if [ -z "$gel_api_base_url" ] || [ -z "$gel_tenant_id" ] || [ -z "$gel_push_token" ]; then
    echo "Missing required arguments!"
    usage
    exit 1
fi


echo "Sending test log lines to: $gel_api_base_url"
echo "Tenant ID: $gel_tenant_id"
echo "Sending 1 log line per second, press Ctrl+C to stop."


# Create an array of possible log messages
dishes=(
  "Peanut butter on toast"
  "Scrambled eggs"
  "Bacon and eggs"
  "Sausage and eggs"
  "Beans on toast"
  "Cereal"
  "Porridge"
  "Muesli"
  "Small cake"
  "Croissant"
  "Roll and black pudding"
  "Bacon and sausage sandwich"
  "Bacon sandwich"
  "Sausage sandwich"
  "Egg sandwich"
  "Burrito"
  "Pulguita"
)

reviews=(
  "excellent"
  "good"
  "average"
  "poor"
  "terrible"
)

while [ 1 ]; do
  log_entry_time=$(date +%s%N)

  # Build up a 'random' log message
  dish=${dishes[$RANDOM % ${#dishes[@]} ]}
  review=${reviews[$RANDOM % ${#reviews[@]} ]}
  log_line="dish=\\\"$dish\\\" review=$review"

  # This needs curl 7.76 or later
  curl --fail-with-body --user $gel_tenant_id:$gel_push_token \
    --header "Content-Type: application/json" \
    --header "X-Scope-OrdID: $gel_tenant_id" \
    --request POST \
    $gel_api_base_url/loki/api/v1/push --data @- <<EOF
{
  "streams": [
    {
      "stream": {
        "job": "test_push",
        "meal": "breakfast"
      },
      "values": [
          [ "$log_entry_time", "$log_line" ]
      ]
    }
  ]
}
EOF

  echo "Sent to $gel_tenant_id on $gel_api_base_url at $(date -d @$((log_entry_time/1000000000))): [ $log_line ]"
  sleep 1
done



