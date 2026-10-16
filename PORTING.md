# Porting xyflow to PSFlow

This file holds the rules for translating `@xyflow/react` and `@xyflow/system`
TypeScript into PSFlow's PureScript. Use it when you port an upstream change
after a baseline bump, re-port a unit to fix a divergence, or write a converter
that crosses an export to the JS surface.

Terms such as *crossed*, *region*, *trace*, and *falsification probe* mean what
[`CONTEXT.md`](CONTEXT.md) says. Commands are in [`README.md`](README.md).

This file supersedes the pattern tables in `tickets/000-overview.md`. Where the
two disagree, the difference is something the divergence backlog,
[Close the divergence backlog](https://github.com/jonbae/PSFlow/issues/93),
showed the older table got wrong.

## Port the mechanism

Port upstream's **mechanism**, not only its results. The mechanism is
everything a consumer or the net can observe:

- Which callbacks fire, how many times, in what order, and with which
  arguments.
- Which keys exist on objects that reach a consumer, and which of them hold
  `undefined`.
- The DOM: elements, attributes, and their order.
- When work happens: which render, which effect, which microtask, and which
  animation frame.

A port can return the right value for every input a test sends and still
diverge on all four. Nearly every entry in the backlog's *Decisions so far* is a
mechanism mismatch that compiled: a continuation that ran on the caller's stack
instead of a microtask, a comparison on a wrapper instead of its payload, a
default resolved one component too late, and a setter that existed and that
nothing called.

Two rules follow from this:

- **Translate first, redesign second.** Keep upstream's call structure, order,
  and data flow, even where PureScript invites a cleaner shape. A redesign
  during a port gives every later difference two possible causes. Redesign
  after the net shows the faithful port matching, as its own change.
- **Idiom lives inside the mechanism.** Newtyped ids, ADTs for discriminated
  unions, and total functions are welcome wherever they change nothing
  observable. Where idiom and mechanism conflict, the mechanism wins. An agent
  whose default is idiomatic PureScript follows this file where the two
  disagree.

A docstring that records a divergence from upstream needs a ticket or a region
beside it. `calculateSnapOffset` in `System.XYDrag.Utils` described its
divergence from the day it was written, and it stayed a bug until it became
[Snap a multi-node drag to the grabbed node, not the lowest-keyed one](https://github.com/jonbae/PSFlow/issues/110).

## Port one unit

A unit is one upstream function, hook, component, or store action. To port
one, follow these steps:

1. Open the unit in `xyflow/`, the vendored baseline that the parity gates
   compare against, and open its callers beside it. A mechanism often lives in
   the caller: a closure over refs, or a `get()` before a `set()`.
2. List the unit's observables. The step is done when every `if`, early
   `return`, `?.`, `??`, `||`, `&&`, default parameter, and `await` in the
   upstream unit has a line in the port or a written reason for having none.
   Missing guards recur on the backlog: an empty change list still fired
   `onNodesChange`, and a pane click deselected nodes on a flow that wasn't
   selectable.
3. Write the types. See [Types](#types).
4. Translate the body. See [Expressions](#expressions) and
   [Effects and timing](#effects-and-timing).
5. If the unit is exported, cross it. See [The boundary](#the-boundary).
6. Prove the port. See [Proving a port](#proving-a-port). The step is done
   when a local proxy test fails with your change reverted and passes with it.

## Types

### Absence: `?`, `undefined`, and `null`

TypeScript has three kinds of absence that PureScript's `Maybe` folds into one.
Decide which of them the unit can observe.

- Type an optional field `field?: T` as `Maybe T`, including a `boolean` that
  has a default. A `Boolean` can't tell a consumer who passed `hidden: false`
  from one who passed nothing. `System.Types.Node` and `System.Types.Edge`
  still type `hidden`, `selected`, `dragging`, `expandParent`, and `animated`
  as `Boolean`; decision 14 on the backlog retypes them.
- Resolve a default where upstream resolves it, not where the value is read.
  `<ReactFlow />` resolves six props before it hands them to
  `<StoreUpdater />`. Passing the raw `Maybe` instead left a removed prop's old
  value in the store. See `resolveSeeded` in `React.Container.InitValues`.
- On the JS surface, represent `undefined` with `Undefinable` from
  `Boundary.Undefined`, not `Nullable`. `toNullable Nothing` emits `null`, and
  upstream emits `undefined`.
- Decide whether the key exists, not only what its value is. A props object
  that upstream builds from JSX attributes carries the key with `undefined`. A
  query result or a callback argument carries only the keys the consumer wrote,
  so a converter prunes absent keys there.
- If `null` and absence mean different things, model three states. The
  key-code props are the example: `null` turns the key off, and absence uses
  the default. Tell them apart with `isNull` from `Boundary.Undefined`.
- Give each `Nothing` one meaning. `updateNodes` once took a `Maybe` where
  `Nothing` meant both "no params" and "a selection drag", which is how
  auto-pan frames reported the wrong node. If two cases share `Nothing`, give
  them an ADT.

### Numbers

- Type `number` as `Number`. Use `Int` only where the value is integral by
  construction, such as an index or a count, and nothing on the JS surface can
  hand in a fraction.
- Round with `Data.Number`. Its `round`, `floor`, `ceil`, and `trunc` are
  `Math.round`, `Math.floor`, `Math.ceil`, and `Math.trunc`. The `Data.Int`
  versions clamp to the 32-bit range and return `0` for `NaN` and infinities,
  where JavaScript keeps `NaN`.
- Translate `a % b` on numbers as `Data.Number.remainder`. `mod` on `Number`
  always returns `0.0`. On `Int`, `div` and `mod` are Euclidean, so
  `-7 / 2` is `-4`; JavaScript truncates, which is `Data.Int.quot` and
  `Data.Int.rem`.
- Format a number that the JS surface reads, such as an SVG path, a CSS value,
  or an id, with `Data.Number.Format.toString`. `show 1.0` is `"1.0"`, where
  `` `${1}` `` is `"1"`. `Test.Parity.Util` explains why path comparisons
  tokenize instead of comparing strings.

### Unions and enums

- Translate a string union or an `enum` as an ADT. When it crosses, its string
  table lives in `Boundary.Enums`.
- Translate a discriminated union (`type: 'position' | 'dimensions' | ...`) as
  an ADT with one constructor per discriminant. Keep the discriminant strings:
  the net witnesses each change by name, such as `onNodesChange:position`.
- Narrow an untagged union, such as `string | string[]`,
  `boolean | number[]`, or `'parent' | CoordinateExtent`, at the boundary with
  the folds in `Boundary.Untagged`. Check the branches in the order that
  upstream's `typeof` and `Array.isArray` tests use.
- Translate `T | T[]` as `Array T`, and read it with `oneOrMany`.

### Collections and order

- Use `Data.Map` and `Data.Set` for lookup, and take every order from somewhere
  else. A JavaScript `Map` iterates in insertion order, and `Data.Map` iterates
  by key. Wherever upstream iterates a `Map`, such as for render order, the
  first drag item, or connection lists, carry the order explicitly: iterate
  the source array and look each element up by id.
- Translate a tuple used as a pair, such as `[x, y]` or an extent, as a
  labelled newtype inside the port, and cross it back out as the positional
  array upstream returns. Surface parity calls the pure functions to catch a
  labelled record where upstream returns an array.

### Identity and equality

- Where upstream compares objects with `===`, `Object.is`, a React dependency
  array, or `memo`, compare by reference with `unsafeRefEq` or
  `UnsafeReference`. Compare the payload, not a wrapper that PureScript
  allocated: `fromUndefinable` builds a fresh `Just` on every call, so a
  reference comparison on the `Maybe` is never equal. `React.Provider.TrackedProp`
  compares the payload for this reason.
- Structural `Eq` where upstream compares references changes how often effects
  and renders run, and the net observes both. `System.Utils.ShallowNodeData`
  documents one such divergence.
- Keep a component's identity stable. A component function created during a
  render is a new component to React, which remounts it. A remount under the
  pointer mid-drag fires `onMouseEnter` up the tree. `Boundary.Wrapper` caches
  one wrapper per component and prop.

### Strings and ids

- Wrap ids in the newtypes from `System.Types.Ids`. When upstream builds a
  string from values that can be absent, reproduce JavaScript's coercion:
  `` `${null}` `` is `"null"`, and `` `${undefined}` `` is `"undefined"`. A null
  handle id that composes as `""` where upstream gives `"null"` is on the
  backlog's ticket set.
- Keep upstream's field names. PureScript accepts `type` as a record label;
  `System.Types.Node` renames it to `nodeType`, which ticket 072 realigns.

### Records and controllers

- Express `Partial`, `Omit`, `Pick`, and intersections as concrete record
  types, and share fields through a row alias such as `NodeBaseRow`.
- Translate a controller that upstream returns as an object of methods, such
  as `XYDrag` or `XYPanZoom`, as a record of `Effect` functions.

## Expressions

- **Truthiness.** `a || b`, `!a`, and `if (a)` test JavaScript's falsy set:
  `false`, `0`, `-0`, `NaN`, `""`, `null`, and `undefined`. Write out the
  members the value can hold. `fromMaybe b a` replaces only `Nothing`, so it's
  a faithful `a ?? b` and an unfaithful `a || b` whenever `a` can be `""` or
  `0`. `connectionExists` in `System.Utils.Edges.General` shows the pattern: a
  handle id of `""` counts as no handle.
- **Explicit values over defaults.** In
  `edge.selectable || (elementsSelectable && edge.selectable === undefined)`,
  an explicit `false` wins and only an absent value inherits the default.
  `React.Component.EdgeWrapper` shows the translation.
- **Optional chaining.** Translate `a?.b` as `map _.b a`, or as `>>=` when `b`
  is optional too. As a condition, `changes?.length` means "present and not
  empty".
- **`get()` before `set()`.** In a zustand action, read each value you need
  from the state as it was before the update, as upstream's `get()` does
  before its `set()`. `React.Store.Reduce` reads both zoom bounds this way.
- **Store methods that return.** When upstream calls a store method and uses
  the result, as with `panBy`, which resolves to whether the viewport moved,
  port a method that returns the result. `React.Store.PanBy` is that method;
  it replaced four adapter copies and a fire-and-forget `PanBy` action that
  lost the answer.
- **Reducer effects.** When an upstream store action also calls d3 or the
  pan-zoom instance, the reducer case emits an `Effect_` descriptor for the
  shell to run. A case that only writes state ports half the action: the zoom
  limit setters existed from ticket 018 onward, and no reducer case called
  them.
- **Strict evaluation.** PureScript evaluates `let` and `where` bindings when
  the enclosing function runs. A JavaScript closure that defers work, such as
  `() => step()`, stays a function or a `defer` in the port. The auto-pan loop
  once built its next frame in a `where` clause, so building one frame built
  the next, and the first auto-pan frame threw a `RangeError`.
- **Errors.** Where upstream calls `onError` or warns, call the same handler
  with the same `errorMessage` code from `System.Constants`, at the same point.
  A `Maybe` or `Either` inside the port is fine if the caller reports where
  upstream reports.

## Effects and timing

- **`await`.** `Aff` continues on the caller's stack when everything it bound
  ran synchronously, and `await` always resumes on a microtask. Wherever the
  continuation must wait for the caller to return, put `awaitMicrotask` from
  `System.FFI.Microtask` after the call. This matters most inside `runOnRef`,
  which isn't re-entrant: a nested call reads the state from before its caller
  began, and the caller's write-back discards the nested write.
- **Animation frames.** Request the next frame inside the continuation, after
  the step it follows has landed, as upstream's `.then` does.
  `React.Container.Pane.Internal` and `System.XYDrag` show the shape.
- **Effect order.** React runs child effects before parent effects, and runs
  every effect on mount whatever its dependencies. A subscription made in an
  effect misses writes from the effects that ran before it. Read store state
  through `useStore` in `React.Hook.Store`, which is upstream's
  `useSyncExternalStore` with its selector memo.
- **Comparisons on mount.** When upstream compares a prop with its previous
  value, seed the previous value the way upstream's `initPrevValues` does, and
  reset it on unmount, because StrictMode remounts.
  `React.Provider.TrackedProp` holds the pattern.
- **Server render.** `parity:boundary`'s mount check renders every hook with
  `react-dom/server`, so anything built on `useSyncExternalStore` needs a server
  snapshot. CI doesn't run that check. After you change `src/React/Hook/` or
  `src/Boundary/`, run `npm run parity:boundary` yourself.
- **Scheduling.** Use `System.FFI.Timer`, `System.FFI.AnimationFrame`, and
  `System.FFI.Microtask`, which keep JavaScript's queue semantics.

## Components and the DOM

- Render the elements and attributes that upstream renders, in its order. The
  backlog lists `aria-describedby` missing on nodes and edges, `aria-label`
  missing on edges, and an extra `<span>` around the attribution link.
- Apply `memo` and `forwardRef` where upstream does. Surface parity compares
  the wrapper chain. See `React.FFI.ForwardRef`.
- Pass handlers the event objects upstream passes, with no extra fields.

## Behavior that lives outside xyflow

Some of upstream's mechanism lives in its libraries and in the platform. When a
unit depends on one, read that library's source too:

- d3-drag's `mousedown` handler stops propagation whether or not its filter
  starts a drag, so binding d3-drag to an element hides the pointer from
  d3-zoom. `React.Hook.Drag` has `disabled` for this reason.
- d3-zoom suppresses a click after a pan until a zero-delay timer fires.
- Upstream passes d3 extra arguments, such as the point and wheel event on a
  pinch or an internal marker on pan-on-scroll, and d3 hands them to the zoom
  handlers. Pass the same arguments.
- React 18 strips `ref` from props, and React 19 leaves it in. `orNullable` in
  `Boundary.Undefined` reads both.

## FFI

- Keep logic in PureScript, where the compiler checks it. Keep FFI for what
  PureScript can't express: `undefined`, `typeof`, d3, DOM APIs that the
  `web-*` packages don't cover, and the scheduler.
- Write foreign functions uncurried (`Fn3`, `EffectFn1`), and pass `Nothing`
  and `Just` in, as in `runFn3 undefinableImpl Nothing Just`, so JavaScript
  never constructs PureScript data.
- Declare library objects opaque with `foreign import data`, such as
  `D3ZoomBehavior`, and read them through accessors.
- Start each foreign module with a comment that says why it exists.

## The boundary

Every export reaches the JS surface through the **boundary module** and a
**converter**, recorded in the **manifest**. `CONTEXT.md` defines all three.

- **Inbound, be lenient.** Read `null` and `undefined` both as `Nothing`,
  because upstream's own types allow `null` in places. Read a prop that
  upstream declares required with `requiredProp`, which names the field when
  it's missing.
- **Outbound, be exact.** Emit upstream's shape: `undefined` rather than
  `null`, positional arrays where upstream returns arrays, and only the keys
  that upstream's object would have.
- **Refuse what the port doesn't model.** A prop that ps-flow doesn't model
  throws at mount with a message, so a dropped prop can't pass for an unset
  one. See `Boundary.Refusal`.
- **Report a truthful shape.** Surface parity compares `Function.length`. Where
  upstream's parameters carry JavaScript defaults, its arity is `0`; record the
  difference as a permanent allowlist entry rather than writing a wrapper that
  misreports its own shape.

## Proving a port

- Close the unit on a **local proxy**: a `spago test` module that fails with
  your change reverted and passes with it. Watch it fail before you trust it
  passing. `test/Test/React/Store/EmptyChanges.purs` and
  `test/Test/React/Store/ResetSelection.purs` are examples.
- For a pure function, add a function-parity property under `test/Test/Parity/`
  with a generator that reaches the edge cases. `snapPosition`'s rounding bug
  passed about one run in 14 under a plain generator, because exact negative
  half-multiples were about 1% of its draws. A generator that put every draw on
  one caught it every run.
- Run `npx spago build` before you run the net. `parity:system` bundles
  whatever is in `output/` and never compiles, so without a build, a
  revert-the-fix run tests the old code.
- Check that the corpus can see the class. Five fixes on the backlog closed
  with the net unchanged, because no scenario drove the condition they fixed.
  When that happens, say so in the PR and name the scenario that would drive
  it.
- Treat everything under `test/` and `parity/` as the oracle. A port changes a
  test, fixture, trace, or register only when its task names that change. A
  difference you accept goes in a region with a written reason and a ticket.
