#!/bin/sh
# Captures the scenarios Order H adds or changes, one net run each.
for s in "$@"; do
  node parity/system/net.mjs --scenario "$s" --out "aamf/step3/order-h/targeted/$s.md" > "aamf/step3/order-h/targeted/$s.log" 2>&1
  echo "$s exit $?"
done
