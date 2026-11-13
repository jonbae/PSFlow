#!/bin/sh
# Runs one check, writes its output to aamf/step3/order-i/<name>.log, and
# appends its command, UTC start and end, and exit code to checks.jsonl.
name="$1"; shift
dir="aamf/step3/order-i"
start=$(date -u +%Y-%m-%dT%H:%M:%SZ)
"$@" > "$dir/$name.log" 2>&1
code=$?
end=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf '{"check":"%s","command":"%s","start":"%s","end":"%s","exit":%d,"log":"%s/%s.log"}\n' \
  "$name" "$*" "$start" "$end" "$code" "$dir" "$name" >> "$dir/checks.jsonl"
echo "$name exit $code"
