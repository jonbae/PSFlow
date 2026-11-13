#!/bin/sh
# Rebuilds the starting commit's two changed PureScript modules, runs the new
# boundary test and the updated mount check against them, and restores the
# final sources. Writes red-declared-minimum.log and red-mount.log here.
set -u
dir="aamf/step3/order-i"
keep=$(mktemp -d)
cp src/Boundary/Chrome.purs src/React/Hook/IsomorphicLayoutEffect.purs src/React/Hook/IsomorphicLayoutEffect.js "$keep/"
git show 6ebf1f19:src/Boundary/Chrome.purs > src/Boundary/Chrome.purs
git show 6ebf1f19:src/React/Hook/IsomorphicLayoutEffect.purs > src/React/Hook/IsomorphicLayoutEffect.purs
rm src/React/Hook/IsomorphicLayoutEffect.js
spago build > "$dir/red-build.log" 2>&1; echo "starting-commit build exit $?"
node --test parity/boundary/declared-minimum.test.mjs > "$dir/red-declared-minimum.log" 2>&1; echo "declared-minimum exit $?"
node parity/boundary/mount.mjs > "$dir/red-mount.log" 2>&1; echo "mount exit $?"
cp "$keep/Chrome.purs" src/Boundary/Chrome.purs
cp "$keep/IsomorphicLayoutEffect.purs" "$keep/IsomorphicLayoutEffect.js" src/React/Hook/
rm -r "$keep"
spago build > /dev/null 2>&1; echo "final build exit $?"
