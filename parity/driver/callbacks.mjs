// Which callback props the driver installs — derived from upstream, never listed.
//
// The net's `callbacks` section can only observe a handler the page actually
// passed to `<ReactFlow />`. A fixture sets three or four; upstream declares 49.
// The other 45 are the interesting ones — a handler **nothing sets** is a
// handler whose absence on one side is invisible, since it fires on neither.
// So the driver installs every one of them, and the log wraps whatever the
// fixture itself set.
//
// ## Why the list is derived
//
// Everything else about the driver may be hand-written: a driver mistake shows
// up identically on both sides, which is what `src/Flow.tsx`'s header says. This
// list is the exception. A handler missing from it is not installed on **either**
// side, so it fires on neither, so the two traces agree — the silent pass this
// whole effort exists to remove, wearing the one disguise the dual-run design
// cannot see through. A baseline bump that adds a handler must not be able to
// leave the net quietly blind to it.
//
// So it comes from the authority: `ReactFlowProps` in the vendored tree, read
// with the TypeScript compiler — the same instrument, for the same reason, as
// `parity/surface/extract-upstream.ts`. A prop is a callback exactly when its
// type is callable, which no name pattern can decide: `onError` and
// `isValidConnection` and `shouldResize` do not share one.
//
// Members inherited from React's `HTMLAttributes<HTMLDivElement>` are excluded,
// exactly as surface parity excludes them from the prop-member diff. They are
// the DOM's ~100 handlers rather than xyflow's, they land on the wrapper div
// rather than in the library, and installing them would put a `pointermove`
// entry in the log for every pixel of every drag.
//
// ## Two registers, and both fail stale
//
// Deriving decides what *is* a callback prop. Two things it cannot decide are
// written down here, each carrying a reason, and each checked — `HOLES` against
// the census by `callbacks.test.mjs`, `UNHANDLED_ANSWERS` against the derivation
// on every build. An entry that stops naming something real fails rather than
// quietly excluding nothing.
//
// A third decision lives in the harness rather than here, because it is about
// the page's behaviour rather than upstream's declarations: **observing is asked
// for explicitly**, since installing a callback prop changes what the page
// renders and other gates drive the same page
// (`../system/harness/call-log.mjs`, `OBSERVE`).

import ts from "typescript";
import { statSync } from "node:fs";
import { join, resolve } from "node:path";

export class CallbackDerivationError extends Error {
  constructor(message) {
    super(message);
    this.name = "CallbackDerivationError";
  }
}

/**
 * What the `callbacks` section **does not reach**, and why.
 *
 * The census assigns 47 exports to this section (mechanism `dual-run-callback`
 * in `parity/census/classification.json`). Installing every callback prop of
 * `ReactFlowProps` puts most of them within reach — a handler's argument types
 * ride along with the handler — and these ten are the remainder. Each is a
 * **hole**: a legitimate resting state carrying a written reason and the ticket
 * that closes it, where an *undeclared* hole is the empty section nobody can
 * read a decision out of.
 *
 * `callbacks.test.mjs` holds this list to the census, so an entry naming an
 * export the census no longer assigns here **fails stale** — and
 * `parity/system/coverage/` now derives the reached side of the same question
 * from runs that happened rather than taking this file's word for it. Where the
 * two disagree the traces win: `OnInit` is a declared hole there whose reason
 * records that the blocker named below has since landed, which is a thing this
 * list cannot notice about itself.
 *
 * `prop` appears on the one hole that is a `ReactFlowProps` prop the driver
 * withholds; the others are not props of this component at all.
 */
export const HOLES = [
  {
    export: "OnInit",
    prop: "onInit",
    issue: 56,
    reason:
      "its single argument is the imperative ReactFlowInstance, which has not crossed the boundary — " +
      "ps-flow refuses the prop at mount (boundary stage 3), so installing it here would fail every " +
      "scenario on one side rather than observing anything.",
  },
  ...["OnResize", "OnResizeStart", "OnResizeEnd", "ShouldResize", "ResizeDragEvent", "ResizeParams", "ResizeParamsWithDirection"].map(
    (name) => ({
      export: name,
      issue: 55,
      reason:
        "a NodeResizer/NodeResizeControl prop rather than a ReactFlow one, and no fixture mounts either " +
        "component — so there is no handler for the driver to install. It needs a fixture that resizes, " +
        "which is the corpus's to add.",
    })
  ),
  ...["UseOnSelectionChangeOptions", "UseOnViewportChangeOptions"].map((name) => ({
    export: name,
    issue: 59,
    reason:
      "the options record a hook is called with, not a prop the flow is passed. Reaching it needs a probe " +
      "component that calls the hook, which is what the hooks and props sections wait on.",
  })),
];

/** The subset that names a `ReactFlowProps` prop, which is what the driver withholds. */
export const NOT_INSTALLED = HOLES.filter((hole) => hole.prop);

/**
 * What an installed handler answers when the fixture set none.
 *
 * For most props *absent* and *present returning undefined* are the same
 * instruction, and the default is `undefined`. For these two they are not: the
 * library reads the return value, and `undefined` is falsy.
 *
 *   * `onBeforeDelete` — upstream skips the gate entirely when the prop is
 *     absent (`system/src/utils/graph.ts`); present, it awaits the answer and a
 *     non-boolean one is returned straight through as the set of things to
 *     delete. Observing deletions must not stop them happening.
 *   * `isValidConnection` — one of the two paths upstream reads it through
 *     coalesces a nullish answer to `true` and the other does not
 *     (`react/src/components/Handle/index.tsx`), so an unset one answering
 *     `undefined` would make every connection invalid on both sides.
 *
 * A handler the fixture *did* set answers whatever it answers; this is only the
 * value that stands in for the prop not being there.
 */
export const UNHANDLED_ANSWERS = {
  onBeforeDelete: true,
  isValidConnection: true,
};

// The vendored declaration the whole list comes from, and the type on it.
const REACT_FLOW_PROPS = "ReactFlowProps";
const PROPS_FILE = "packages/react/src/types/component-props.ts";
const SYSTEM_ENTRY = "packages/system/src/index.ts";

/**
 * The callable members of `typeName` in `file`, in declaration order.
 *
 * `root` is the directory that counts as the library's own source: a member
 * declared outside it is inherited from somewhere else — React's
 * `HTMLAttributes`, in the real case — and is not xyflow's callback.
 *
 * Parameterised rather than hardcoded so that `callbacks.test.mjs` can point the
 * whole derivation at a miniature of the same shape, and run on a clean clone
 * where the vendored tree is not there at all.
 */
export const callablePropsOf = ({ file, typeName, root, paths = {} }) => {
  if (!statSync(file, { throwIfNoEntry: false })?.isFile()) {
    throw new CallbackDerivationError(
      `no ${typeName} source at ${file} — the vendored upstream tree is missing or has moved it. ` +
        `Re-vendor \`xyflow/\` and try again.`
    );
  }

  const program = ts.createProgram([file], {
    target: ts.ScriptTarget.ESNext,
    module: ts.ModuleKind.ESNext,
    moduleResolution: ts.ModuleResolutionKind.Bundler,
    jsx: ts.JsxEmit.ReactJSX,
    noEmit: true,
    skipLibCheck: true,
    skipDefaultLibCheck: true,
    strict: false,
    esModuleInterop: true,
    paths,
  });
  const checker = program.getTypeChecker();
  const source = program.getSourceFile(file);

  let declaration;
  ts.forEachChild(source, (node) => {
    if (ts.isInterfaceDeclaration(node) && node.name.text === typeName) declaration = node;
  });
  if (!declaration) {
    throw new CallbackDerivationError(
      `${file} declares no \`interface ${typeName}\`. Upstream renamed or moved it, which is itself a ` +
        `finding — the driver would otherwise install nothing and the section would compare clean.`
    );
  }

  const declared = checker.getDeclaredTypeOfSymbol(checker.getSymbolAtLocation(declaration.name));

  // Declared under `root`, and **not** under a `node_modules` inside it —
  // the same two-part test `parity/surface/extract-upstream.ts` applies for the
  // same reason. The first half alone would count React's own handlers as
  // xyflow's the moment anyone ran an install inside the vendored tree, and the
  // driver built from it would log a pointer move per pixel of every drag, on
  // both sides, comparing clean.
  const own = (symbol) =>
    (symbol.getDeclarations() ?? []).some((d) => {
      const path = d.getSourceFile().fileName.replace(/\\/g, "/");
      return path.startsWith(root.replace(/\\/g, "/") + "/") && !path.includes("/node_modules/");
    });

  return checker
    .getPropertiesOfType(declared)
    .filter(own)
    .filter((symbol) => {
      const type = checker.getTypeOfSymbolAtLocation(symbol, symbol.valueDeclaration ?? declaration);
      return checker.getSignaturesOfType(type.getNonNullableType(), ts.SignatureKind.Call).length > 0;
    })
    .map((symbol) => symbol.getName());
};

/**
 * Register entries that no longer name a callback prop of `derived`, described
 * so a build failure says which register and which entry.
 *
 * This is the **stale** rule the whole repository runs on: an entry bites when
 * it stops being true instead of accumulating silently. A withheld prop upstream
 * deleted would otherwise keep withholding nothing, and an unset-answer entry
 * would keep answering for a prop nobody passes.
 */
export const staleEntries = (derived) => {
  const isCallback = new Set(derived);
  const withheld = new Set(NOT_INSTALLED.map((hole) => hole.prop));
  return [
    ...NOT_INSTALLED.filter((hole) => !isCallback.has(hole.prop)).map((hole) => `NOT_INSTALLED: ${hole.prop}`),
    ...Object.keys(UNHANDLED_ANSWERS)
      .filter((prop) => !isCallback.has(prop))
      .map((prop) => `UNHANDLED_ANSWERS: ${prop}`),
    // The two registers contradicting each other, which is neither one being
    // stale on its own: an answer for a prop nothing installs is an answer
    // nothing can ever give. Dropping it quietly is what a filter would do.
    ...Object.keys(UNHANDLED_ANSWERS)
      .filter((prop) => withheld.has(prop))
      .map((prop) => `UNHANDLED_ANSWERS names ${prop}, which NOT_INSTALLED withholds`),
  ];
};

/**
 * What the driver installs, and what each answers when unset — the whole
 * manifest the page is built with.
 *
 * `{ props, unhandled, holes }`: `props` is upstream's callback props minus the
 * ones `NOT_INSTALLED` names, `unhandled` is `UNHANDLED_ANSWERS` narrowed to
 * what was installed, and `holes` is `NOT_INSTALLED` itself, carried into the
 * bundle so the reason travels with the page rather than only with this file.
 *
 * Throws `CallbackDerivationError` on a vendored tree that cannot be read, on a
 * register entry naming a prop that is no longer a callback, and on a
 * derivation that came back implausibly small.
 */
export const observedCallbacks = (repoRoot) => {
  const root = resolve(repoRoot, "xyflow");
  const derived = callablePropsOf({
    file: join(root, PROPS_FILE),
    typeName: REACT_FLOW_PROPS,
    root,
    // The react package imports the system package by its published name, the
    // same redirection `build.mjs` and `oracle/esbuild.mjs` both make.
    paths: { "@xyflow/system": [join(root, SYSTEM_ENTRY)] },
  });

  // Upstream declares 49 of them at the pinned baseline. A parse that came back
  // with a handful found a file it could resolve nothing in, and the driver it
  // built would be blind to the difference between the two libraries' handlers
  // without anything going red.
  if (derived.length < 40) {
    throw new CallbackDerivationError(
      `read only ${derived.length} callback props from ${REACT_FLOW_PROPS} — the derivation is wrong, ` +
        `not upstream. A driver built from it would install almost nothing and the \`callbacks\` ` +
        `section would compare clean on both sides.`
    );
  }

  const stale = staleEntries(derived);
  if (stale.length) {
    throw new CallbackDerivationError(
      `stale entries in parity/driver/callbacks.mjs — each names a prop ${REACT_FLOW_PROPS} no longer ` +
        `declares as a callback:\n` +
        stale.map((s) => `  - ${s}`).join("\n") +
        `\nAn entry that stops corresponding to reality fails here rather than quietly excluding ` +
        `nothing, exactly as a region or an allowlist entry does.`
    );
  }

  const withheld = new Set(NOT_INSTALLED.map((hole) => hole.prop));
  const props = derived.filter((prop) => !withheld.has(prop));

  // `unhandled` goes across whole: a register contradicting the other is a
  // failure above rather than something narrowed away here.
  return { props, unhandled: { ...UNHANDLED_ANSWERS }, holes: NOT_INSTALLED };
};
