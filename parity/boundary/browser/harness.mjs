// The node half of the boundary's browser differential.
//
// A server render runs no effects, so a prop that `<StoreUpdater />` writes,
// that a pane or a node reads after mount, or that a measurement decides is
// invisible to the boundary's other tests. This harness bundles
// `browser/page.mjs` with a case table twice, once per side, and loads each
// bundle into its own Chromium page with upstream's stylesheet. The two
// bundles differ in what `@xyflow/react` resolves to and in nothing else: the
// published upstream package, as every other boundary test imports it, or
// ps-flow's `index.js`.
//
// `open(casesFile)` returns `run(name)`, which runs one case on both pages and
// returns both results, and `close()`.
import { build } from 'esbuild';
import { chromium } from '@playwright/test';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '..', '..', '..');
const require = createRequire(import.meta.url);

const sides = {
  upstream: null,
  psflow: resolve(repoRoot, 'index.js'),
};

// The bundle for one side. The case table is a virtual module so that one
// page source serves every table.
async function bundle(side, casesFile) {
  const alias = {
    react: resolve(repoRoot, 'node_modules/react'),
    'react-dom': resolve(repoRoot, 'node_modules/react-dom'),
  };
  if (sides[side]) alias['@xyflow/react'] = sides[side];
  const result = await build({
    entryPoints: [join(here, 'page.mjs')],
    bundle: true,
    write: false,
    format: 'iife',
    platform: 'browser',
    logLevel: 'silent',
    alias,
    define: { 'process.env.NODE_ENV': '"development"', __SIDE__: JSON.stringify(side) },
    plugins: [
      {
        name: 'contract-cases',
        setup(b) {
          b.onResolve({ filter: /^contract:cases$/ }, () => ({ path: casesFile }));
        },
      },
    ],
  });
  const text = result.outputFiles[0].text;
  // The provenance check the driver makes: a side that bundled the other
  // library would compare a library with itself.
  const psflowMarker = /\/\/ output\/Boundary\//.test(text);
  if (psflowMarker !== (side === 'psflow')) {
    throw new Error(`the ${side} bundle ${psflowMarker ? 'contains' : 'lacks'} ps-flow's output`);
  }
  return text;
}

const stylesheet = require.resolve('@xyflow/react/dist/style.css');

export async function open(casesFile) {
  const browser = await chromium.launch();
  const pages = {};
  for (const side of Object.keys(sides)) {
    const page = await browser.newPage({ viewport: { width: 1000, height: 800 } });
    page.on('pageerror', () => {});
    await page.setContent(
      '<!doctype html><html><body style="margin:0"><div id="root" style="width:800px;height:600px"></div></body></html>'
    );
    await page.addStyleTag({ path: stylesheet });
    await page.addScriptTag({ content: await bundle(side, casesFile) });
    pages[side] = page;
  }
  const names = await pages.upstream.evaluate(() => window.contract.names());
  return {
    names,
    async run(name) {
      const [upstream, psflow] = await Promise.all(
        Object.values(pages).map((page) => page.evaluate((n) => window.contract.run(n), name))
      );
      return { upstream, psflow };
    },
    close: () => browser.close(),
  };
}
