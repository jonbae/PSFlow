// Self-test for the PureScript record reader the two boundary gates share.
//
// The reader is the reason those gates can claim anything: a comparison
// between two records is only as good as the field lists behind it, and a
// reader that quietly returns the wrong list turns both gates green by
// construction. That is not hypothetical here — `InternalNode` compared one
// field out of twenty-nine until the reader learned to follow a row, and the
// undeclared `nodeType`/`type` rename underneath it had been invisible the
// whole time.
//
// Failure paths are not exercised: `fail()` calls `process.exit`, which would
// take the runner with it. What these do exercise is that every shape the
// source actually uses reads back correctly, and that a composition is
// expanded rather than approximated.

import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { recordEntries, recordFields } from "./purs.mjs";

const repoRoot = resolve(fileURLToPath(import.meta.url), "..", "..", "..");
const inRepo = (path) => join(repoRoot, path);

const scratch = mkdtempSync(join(tmpdir(), "psflow-purs-"));
let written = 0;
// A throwaway module, so a shape can be stated in three lines rather than
// found in the source and depended on not to move.
const module_ = (body) => {
  const path = join(scratch, `Fixture${written++}.purs`);
  writeFileSync(path, body, "utf8");
  return path;
};

test("a record written as one literal reads back as itself", () => {
  const path = module_(`
type Point =
  { x :: Number
  , y :: Number
  }
`);
  assert.deepEqual(recordFields(path, "Point"), ["x", "y"]);
});

test("a record composed from a row is expanded, tail last", () => {
  const path = module_(`
type BaseRow r =
  ( id :: String
  , name :: String
  | r
  )

type Base = Record (BaseRow ())

type Extended = Record (BaseRow (extra :: Boolean))
`);
  assert.deepEqual(recordFields(path, "Base"), ["id", "name"]);
  assert.deepEqual(recordFields(path, "Extended"), ["id", "name", "extra"]);
});

test("`{ label :: T | Row }` is a composition too, not a one-field record", () => {
  const path = module_(`
type BaseRow r =
  ( id :: String
  | r
  )

type WithInternals = { internals :: Internals | BaseRow () }
`);
  assert.deepEqual(recordFields(path, "WithInternals"), ["internals", "id"]);
});

test("two rows compose, and a synonym in between is followed", () => {
  const path = module_(`
type LeftRow r =
  ( a :: Int
  | r
  )

type RightRow r =
  ( b :: Int
  | r
  )

type Both = Record (LeftRow (RightRow (c :: Int)))
`);
  assert.deepEqual(recordFields(path, "Both"), ["a", "b", "c"]);
});

test("a parameterised record synonym is applied, not just named", () => {
  const path = module_(`
type BaseRow r =
  ( a :: Int
  | r
  )

type WithOption o = Record (BaseRow (option :: Maybe o))

type Applied = WithOption String
`);
  assert.deepEqual(recordFields(path, "Applied"), ["a", "option"]);
});

test("an argument is read in the scope that passed it, not the one that uses it", () => {
  // `OuterRow` hands `InnerRow` the *name* `q`, which means nothing inside
  // `InnerRow` — it has to be read back where it was written. Resolving it in
  // the scope that used it instead would drop `leaf` silently, which is the
  // shape of failure this reader exists to make impossible.
  const path = module_(`
type InnerRow r =
  ( inner :: Int
  | r
  )

type OuterRow q =
  ( outer :: Int
  | InnerRow q
  )

type Composed = Record (OuterRow (leaf :: Int))
`);
  assert.deepEqual(recordFields(path, "Composed"), ["outer", "inner", "leaf"]);
});

test("a synonym sees only its own parameters — an enclosing one is not in scope", () => {
  // `Stray` names `q`, which `OuterRow` binds and `Stray` does not. Walking out
  // to the enclosing scope would capture it and graft `leaf` on twice; the
  // right answer is that an unbound tail contributes nothing.
  const path = module_(`
type Stray r =
  ( stray :: Int
  | q
  )

type OuterRow q =
  ( outer :: Int
  | Stray q
  )

type Composed = Record (OuterRow (leaf :: Int))
`);
  assert.deepEqual(recordFields(path, "Composed"), ["outer", "stray"]);
});

test("an unapplied tail contributes nothing rather than failing", () => {
  const path = module_(`
type OpenRow r =
  ( a :: Int
  | r
  )

type Closed = Record (OpenRow ())
`);
  assert.deepEqual(recordFields(path, "Closed"), ["a"]);
});

test("field types come back alongside the labels, whitespace collapsed", () => {
  const path = module_(`
type BaseRow r =
  ( handler ::
      String
      -> Effect Unit
  | r
  )

type Handlers = Record (BaseRow (flag :: Boolean))
`);
  assert.deepEqual(recordEntries(path, "Handlers"), [
    { name: "handler", type: "String -> Effect Unit" },
    { name: "flag", type: "Boolean" },
  ]);
});

test("a quoted label survives, and a `--` inside one is not a comment", () => {
  const path = module_(`
type Aria =
  { "aria-label" :: String -- the real comment
  , plain :: Int
  }
`);
  assert.deepEqual(recordFields(path, "Aria"), ["aria-label", "plain"]);
});

// The reader is only useful if it says the same thing about the real source
// that the gates read, so these pin the two records the composition exists for.
test("ReactFlowInstance reads as all thirty-two members", () => {
  const fields = recordFields(inRepo("src/React/Types/Instance.purs"), "ReactFlowInstance");
  assert.equal(fields.length, 32);
  assert.equal(fields[0], "getNodes", "the general helpers come first");
  assert.ok(fields.includes("zoomIn"), "the viewport helpers are folded in");
  assert.equal(fields.at(-1), "viewportInitialized", "and the one member neither row carries");
});

test("InternalNodeBase carries the node's own fields, not just `internals`", () => {
  const fields = recordFields(inRepo("src/System/Types/Node.purs"), "InternalNodeBase");
  assert.ok(fields.includes("internals"));
  assert.ok(fields.includes("nodeType"), "the field whose rename went undeclared for as long as this read short");
  assert.ok(fields.length > 20, `expected the whole node row, got ${fields.length} field(s)`);
});

test("a path-shaped edge props record is its shared row plus pathOptions", () => {
  const base = recordFields(inRepo("src/React/Types/Edges.purs"), "EdgeComponentProps");
  const bezier = recordFields(inRepo("src/React/Types/Edges.purs"), "BezierEdgeProps");
  assert.deepEqual(bezier, [...base, "pathOptions"]);
});
