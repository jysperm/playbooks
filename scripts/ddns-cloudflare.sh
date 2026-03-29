#!/bin/bash

# ddns-cloudflare - Update Cloudflare DNS records with current IP address

set -euo pipefail

UPDATE_4=false
UPDATE_6=false

while getopts "46" opt; do
  case "$opt" in
    4) UPDATE_4=true ;;
    6) UPDATE_6=true ;;
    *) echo "Usage: ddns-cloudflare [-4] [-6] <record-name> [record-name ...]" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

if ! $UPDATE_4 && ! $UPDATE_6; then
  echo "Usage: ddns-cloudflare [-4] [-6] <record-name> [record-name ...]" >&2
  echo "  -4  Update A record (IPv4)" >&2
  echo "  -6  Update AAAA record (IPv6)" >&2
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Usage: ddns-cloudflare [-4] [-6] <record-name> [record-name ...]" >&2
  exit 1
fi

if [ -z "${CF_API_TOKEN:-}" ]; then
  echo "Error: CF_API_TOKEN is not set" >&2
  exit 1
fi

CF_API="https://api.cloudflare.com/client/v4"

cf_api() {
  local method="$1" path="$2"
  shift 2
  curl -sf -X "$method" "$CF_API$path" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    "$@"
}

# Resolve zone ID from record name by progressively stripping subdomains
find_zone_id() {
  local domain="$1"
  while [ "$domain" != "${domain#*.}" ]; do
    local result
    result=$(cf_api GET "/zones?name=$domain&status=active")
    if [ "$(echo "$result" | jq -r '.result_info.count')" -gt 0 ]; then
      echo "$result" | jq -r '.result[0].id'
      return 0
    fi
    domain="${domain#*.}"
  done
  return 1
}

# Update or create a DNS record
update_record() {
  local zone_id="$1" record_name="$2" record_type="$3" current_ip="$4"

  local result count
  result=$(cf_api GET "/zones/$zone_id/dns_records?type=$record_type&name=$record_name")
  count=$(echo "$result" | jq -r '.result_info.count')

  if [ "$count" -eq 0 ]; then
    echo "  Creating $record_type: $record_name -> $current_ip"
    cf_api POST "/zones/$zone_id/dns_records" \
      -d "{\"type\":\"$record_type\",\"name\":\"$record_name\",\"content\":\"$current_ip\",\"ttl\":300}" > /dev/null
    echo "  Created"
  else
    local record_id existing_ip
    record_id=$(echo "$result" | jq -r '.result[0].id')
    existing_ip=$(echo "$result" | jq -r '.result[0].content')

    if [ "$existing_ip" = "$current_ip" ]; then
      echo "  $record_type unchanged"
      return
    fi

    echo "  Updating $record_type: $existing_ip -> $current_ip"
    cf_api PATCH "/zones/$zone_id/dns_records/$record_id" \
      -d "{\"content\":\"$current_ip\"}" > /dev/null
    echo "  Updated"
  fi
}

# Get current IPs
if $UPDATE_4; then
  IPV4=$(curl -sf -4 https://www.cloudflare.com/cdn-cgi/trace | sed -n 's/^ip=//p') || true
  if [ -z "$IPV4" ]; then
    echo "Warning: Failed to get current IPv4 address" >&2
  else
    echo "Current IPv4: $IPV4"
  fi
fi

if $UPDATE_6; then
  IPV6=$(curl -sf -6 https://www.cloudflare.com/cdn-cgi/trace | sed -n 's/^ip=//p') || true
  if [ -z "$IPV6" ]; then
    echo "Warning: Failed to get current IPv6 address" >&2
  else
    echo "Current IPv6: $IPV6"
  fi
fi

for RECORD_NAME in "$@"; do
  echo "Processing $RECORD_NAME ..."

  ZONE_ID=$(find_zone_id "$RECORD_NAME") || {
    echo "Error: Could not find zone for $RECORD_NAME" >&2
    continue
  }

  if $UPDATE_4 && [ -n "${IPV4:-}" ]; then
    update_record "$ZONE_ID" "$RECORD_NAME" "A" "$IPV4"
  fi

  if $UPDATE_6 && [ -n "${IPV6:-}" ]; then
    update_record "$ZONE_ID" "$RECORD_NAME" "AAAA" "$IPV6"
  fi
done
