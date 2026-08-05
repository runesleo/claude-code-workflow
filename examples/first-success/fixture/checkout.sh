#!/usr/bin/env bash
set -euo pipefail

subtotal_cents="${1:-2500}"
discount_percent="${2:-10}"

if ! [[ "$subtotal_cents" =~ ^[0-9]+$ ]] || \
   ! [[ "$discount_percent" =~ ^[0-9]+$ ]] || \
   [ "$discount_percent" -gt 100 ]; then
  echo "usage: ./checkout.sh SUBTOTAL_CENTS DISCOUNT_PERCENT" >&2
  exit 2
fi

final_cents=$((subtotal_cents - discount_percent))
printf '%s\n' "$final_cents"
