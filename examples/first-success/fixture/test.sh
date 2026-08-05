#!/usr/bin/env bash
set -euo pipefail

assert_total() {
  subtotal="$1"
  discount="$2"
  expected="$3"
  actual="$(./checkout.sh "$subtotal" "$discount")"
  if [ "$actual" != "$expected" ]; then
    echo "TEST_FAIL subtotal=$subtotal discount=$discount expected=$expected got=$actual" >&2
    exit 1
  fi
}

assert_total 2500 10 2250
assert_total 2500 0 2500
assert_total 2500 100 0
assert_total 999 10 900

echo "FIRST_SUCCESS_FIXTURE_OK"
