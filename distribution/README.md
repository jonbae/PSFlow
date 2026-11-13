# The package

`npm pack` publishes `dist/`, which `npm run build:package` builds. A
JavaScript or TypeScript consumer installs it in place of `@xyflow/react`:

```js
import { ReactFlow, Background } from 'ps-flow';
import 'ps-flow/dist/style.css';
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
| `index.d.ts`, `types/` | Upstream's declarations, generated from the vendored source | See [the declarations](#the-declarations). |
| `style.css`, `base.css` | The pinned `@xyflow/react`'s published stylesheets, byte for byte | Upstream builds them with five PostCSS plugins this repo does not have, and these exact files are what the driver page loads on both sides of every net run. |
| `xyflow-LICENSE` | `xyflow/LICENSE` | The declarations and stylesheets are copies of upstream's, under its MIT license. |

React and React DOM are peer dependencies at `^18.3.0`, the version every gate
runs. Upstream accepts React 17 and later; ps-flow does not claim a version it
has not run. `@types/react` is an optional peer, as upstream's is.

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
file where a type or its documentation can say the difference: `setState`'s
`replace` parameter is `false | undefined`, and `useStoreApi`'s documentation
lists the writes ps-flow refuses. An overlay whose text no longer occurs once
fails the build as stale. A **note** goes into the header of `dist/index.d.ts`,
which lists every difference: the store's exclusions, `defaultEdgeOptions` keys
outside its type, handlers on rebuilt nodes in an uncontrolled flow, the
styles warning's wording, and the absence of a UMD build.

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
  same `typeof`, arity and React wrapper kind. `require('ps-flow')` reaches the
  same names on a Node version that loads ES modules through `require`.
- A flow with the chrome components renders the same markup through the
  package as through `index.js` and logs nothing. An esbuild bundle of a
  consumer that imports the package and `ps-flow/dist/style.css` does too.
- The stylesheets are the bytes the driver page loads.
- `consumer/consumer.tsx` type-checks under bundler and Node 16 resolution with
  `skipLibCheck` off, so every published declaration is checked too. Its
  `@ts-expect-error` lines fail if an overlay stops applying.
- The declarations name upstream's exports, value and type, and their 68
  values are the runtime's.

`parity/boundary/declared-minimum.test.mjs` holds the other direction: every
component, hook and function, given only what upstream's declarations require,
mounts, runs or returns upstream's value on both sides.

The check does not prove behavior: surface parity, the boundary checks, the
conformance suite and the net do, through `index.js`, and the package check
holds the package to `index.js`.
