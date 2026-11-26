# The package

`npm pack` publishes `dist/`, which `npm run build:package` builds. A
JavaScript or TypeScript consumer installs it in place of `@xyflow/react`:

```js
import { ReactFlow, Background } from 'ps-flow';
import 'ps-flow/dist/style.css';
```

CommonJS consumers can call `require('ps-flow')`. The same UMD artifact
supports AMD with `react` and `react-dom` as loader dependencies. For a classic
browser script, serve the files from the installed packages and load React 18
and React DOM 18 before ps-flow. The library is available as
`window.ReactFlow`, with the component at `window.ReactFlow.ReactFlow`.

```html
<link rel="stylesheet" href="ps-flow/dist/style.css">
<script src="react/umd/react.production.min.js"></script>
<script src="react-dom/umd/react-dom.production.min.js"></script>
<script src="ps-flow/dist/umd/index.js"></script>
```

```sh
npm run build:package   # spago build, then distribution/build.mjs: writes dist/
npm run parity:package  # pack, install into a scratch consumer, check it
npm run test:package    # node --test over the declaration pipeline
```

`npm pack` runs `build:package` first through `prepack`. `package.json` stays
`private`, at version `0.0.0`: publishing is a separate decision.

## What `dist/` holds

| File | Built from | Why this way |
|---|---|---|
| `index.js` | `index.js` and the compiled PureScript it reaches, bundled by esbuild into one ES module | `output/` is 145 MB of compiler artifacts. The bundle inlines only `index.js` and `output/`; the build fails if it inlines anything else, or if the packages it imports are not exactly the manifest's runtime `dependencies` and `peerDependencies`. |
| `umd/index.js` | The same entry bundled with D3 and the production JSX runtime | CommonJS, AMD and classic scripts share this artifact. React and React DOM are supplied by the host. The bundle uses production mode. |
| `index.d.ts`, `types/` | Upstream's declarations, generated from the vendored source | See [the declarations](#the-declarations). |
| `style.css`, `base.css` | The pinned `@xyflow/react`'s published stylesheets, byte for byte | Upstream builds them with five PostCSS plugins this repo does not have, and these exact files are what the driver page loads on both sides of every net run. |
| `xyflow-LICENSE` | `xyflow/LICENSE` | The declarations and stylesheets are copies of upstream's, under its MIT license. |

React and React DOM are peer dependencies at `^18.3.1`, which admits one
published release, 18.3.1. CI runs every gate and check on it, and the package
check names the release it ran on. The range leaves out 18.3.0: every gate
passes there, but its `react` package does not export `act`, so the boundary
tests cannot run. Upstream accepts React 17 and later; ps-flow does not claim a
version it has not fully verified. `@types/react` is an optional peer, as
upstream's is.

## The declarations

ps-flow publishes upstream's declarations rather than declarations derived from
its PureScript types: the JS surface is upstream's API, and a PureScript record
or sum type is not what a JavaScript consumer handles. `declarations.mjs`
builds them in five steps:

1. Compile the vendored `@xyflow/react` source with upstream's compiler options
   and keep the declarations. Any diagnostic fails the build. Each of the 170
   files must equal the pinned published package's, apart from its source-map
   comment.
2. Move each file from `<package>/src/` to `types/<package>/`.
3. Rewrite every module specifier. `@xyflow/system` becomes a path into
   `types/system/`, and each relative specifier names its file with `.js`,
   because the package's `type` is `module` and Node's resolution adds no
   extensions. Usage examples in comments import from `ps-flow`.
4. Keep the 103 files the entry reaches. The rest describe upstream internals,
   and some import `zustand`, which ps-flow does not use.
5. Apply the overlays in `gaps.mjs`.

The bare specifiers left are `react`, `react/jsx-runtime`, `d3-drag`,
`d3-selection` and `d3-zoom`. The build fails unless the manifest names a types
package for each, so `@types/d3-drag`, `@types/d3-selection` and
`@types/d3-zoom` are dependencies, as they are of `@xyflow/system`.

### Gaps

`gaps.mjs` is the register of where ps-flow knowingly differs from upstream at
the JS surface, as the declarations state it. An **overlay** edits a generated
file where a type or its documentation can say the difference; an overlay
whose text no longer occurs once fails the build as stale. The register has no
overlays. A **note** goes into the header of `dist/index.d.ts`, which lists
every difference: what the store's internals hold for values they cannot
convert, whole-state replacement, and the styles warning's wording.

The documentation comments are otherwise upstream's, and so is the behavior
they describe. ps-flow matches it where its gates say so; behavior no gate
covers yet is listed as gate-pending in `parity/changelog-audit/report.md`.

## What `parity:package` checks

It packs `dist/`, extracts the tarball into a scratch consumer whose
`node_modules` holds only links to the manifest's dependencies and peers, and
checks that:

- The tarball holds `package.json`, `README.md` and `dist/`, including every
  path the manifest's `main`, `types` and `exports` name.
- `import 'ps-flow'` publishes the names `index.js` publishes, each with the
  same `typeof`, arity and React wrapper kind. The UMD build exposes the same
  API and renders the same markup through CommonJS, AMD and a classic script.
- A flow with the chrome components renders the same markup through the
  package as through `index.js` and logs nothing. An esbuild bundle of a
  consumer that imports the package and `ps-flow/dist/style.css` does too.
- The stylesheets are the bytes the driver page loads.
- `consumer/consumer.tsx` type-checks under bundler and Node 16 resolution with
  `skipLibCheck` off, so every published declaration is checked too. An
  overlay would add an `@ts-expect-error` line there, which fails if the
  overlay stops applying.
- The declarations name upstream's exports, value and type, and their 68
  values are the runtime's.

`parity/boundary/declared-minimum.test.mjs` holds the other direction: every
component, hook and function, given only what upstream's declarations require,
mounts, runs or returns upstream's value on both sides.

The check does not prove behavior: surface parity, the boundary checks, the
conformance suite and the net do, through `index.js`, and the package check
holds the package to `index.js`.
