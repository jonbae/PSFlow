#!/bin/sh
# Breaks three things in a packed, installed package and shows which
# parity:package check reports each. Run after `npm run build:package`.
set -u
repo=$(pwd)
tsc="$repo/node_modules/typescript/bin/tsc"
consumer=$(node distribution/check.mjs --keep | sed -n 's/^consumer left at //p')
cd "$consumer" || exit 1

echo "## 1. The store-replace overlay removed: the bundler type-check"
f=node_modules/ps-flow/dist/types/react/hooks/useStore.d.ts
cp "$f" "$f.keep"
sed -i.tmp 's/replace?: false | undefined/replace?: boolean | undefined/' "$f"
node "$tsc" -p tsconfig.esnext.json > out.txt 2>&1; code=$?
cat out.txt; echo "exit $code"
mv "$f.keep" "$f"

echo "## 2. Relative specifiers without .js: the Node 16 type-check"
cp -R node_modules/ps-flow/dist/types ../types.keep
find node_modules/ps-flow/dist/types -name '*.d.ts' -exec sed -i.tmp -E "s#(from '\.[^']*)\.js'#\1'#g" {} +
node "$tsc" -p tsconfig.node16.json > out.txt 2>&1; code=$?
head -5 out.txt; echo "... $(wc -l < out.txt) lines; exit $code"
node "$tsc" -p tsconfig.esnext.json > out.txt 2>&1; echo "bundler resolution still passes: exit $?"
rm -rf node_modules/ps-flow/dist/types; mv ../types.keep node_modules/ps-flow/dist/types

echo "## 3. A layout effect on the server: the render check"
sed -i.tmp 's/var hasWindow = typeof window !== "undefined";/var hasWindow = true;/' node_modules/ps-flow/dist/index.js
node probe.mjs render ps-flow | node -e '
let s = ""; process.stdin.on("data", (d) => (s += d)).on("end", () => {
  const { logged } = JSON.parse(s);
  console.log(`logged ${logged.length}:`, logged.map(([level, text]) => `${level}: ${text.slice(0, 60)}`));
});'

cd "$repo" && rm -rf "$(dirname "$consumer")"
