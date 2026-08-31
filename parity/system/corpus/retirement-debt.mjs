// The retirement debt — the corpus's third source (#61).
//
// Ten hand-authored parity assertions lived in two ps-flow browser specs, and
// the gate-topology spec made their retirement **conditional on the net covering
// them** rather than on anyone deciding they were redundant. Nothing here is
// retired for redundancy: a gate survives if it reports a class of root cause at
// the cheapest point that can see it, and only what *re-reports* retires. This
// file is where the net starts re-reporting, and `RETIREMENTS` below is the
// per-test record of what was handed over to what.
//
// ## Why the debt was owed at all
//
// Both specs drove a ps-flow **contract** component — a page only ps-flow ever
// mounted, `Smoke.tsx` and `NodePropsGuard.tsx` — and asserted values somebody
// had read out of xyflow and written down. That is the failure mode this whole
// effort exists to close: the `xPos`/`yPos` rename survived from 12.3.5 because
// the check that could have seen it printed instead of failing, and a
// hand-authored expected string is the same mistake with a louder failure. Both
// flows are now **fixtures** — `flow/chrome-defaults.ts` and
// `nodes/props-record.ts` — so upstream mounts them too, and every assertion
// that was a string in a spec is a comparison against a running xyflow.
//
// ## Retirement is recorded per test, never per file
//
// `smoke.spec.ts` was never one thing. Two of its ten tests are **liveness** —
// that the driver page mounts at all, and that a five-second session prints
// nothing — and those stay permanently, moved onto a driver route now that the
// contract page they used to mount is gone. The other eight were the repo's
// densest hand-authored parity assertions, and one of them, `node drag fires
// onNodesChange`, was the **only callback assertion on either surface**: losing
// it inside a file-level retirement would have been a real regression that
// nothing would have reported. Splitting the file per test is what made the
// retirement resolvable at all.
//
// ## What each scenario buys over the assertion it replaces
//
// The assertions asked one question each — is the transform different, is the
// class present, is the count two. A scenario asks none and observes all seven
// sections of both sides' traces, so what was one boolean becomes the entire
// settled DOM, the exact callback sequence, and the console beside it. The
// stimulus is preserved exactly; only the expected value is dropped, because
// upstream is running beside it.
//
// ## Where the ids come from
//
// Semantic, and named for the stimulus rather than for the retired test — a
// scenario outlives the retirement that motivated it. They deliberately avoid
// the thirty names `reserved.mjs` holds: `drag-node-reports-changes` sits very
// close to `drag-node-release`, and the two are not the same experiment. That
// one drags a flow which already carries a selection, because #5684 was about
// the effect that re-subscribes between two drags; this one drags a pristine
// flow whose three chrome components are all at their defaults, which is what
// the smoke page did and what nothing else in the corpus does.
//
// ## The one retirement with no scenario of its own
//
// `Background renders behind the flow` asserted that an element existed in a
// settled page. The **mount-only baseline** derived for `flow/chrome-defaults.ts`
// is that page, compared in full against upstream's, so writing a scenario that
// mounted and did nothing would be writing the baseline a second time under a
// different name. It is cited by the id the registry derives, which resolves in
// the same name space every other citation does.
//
// ## The node-props condition, and why it is not the one that was written down
//
// The gate-topology spec said the node-props spec retires "when the net's
// `props` section is green". It does not retire on that, and the reason is worth
// having in writing rather than discovering twice.
//
// The `props` section is written by the **probe** components, and a probed run
// is compared only at its own observation level — the graph a probe replaced is
// not compared at all. Both of the retired spec's claims are *about* the graph:
// a child parented to a node that sits somewhere else, and what its record says
// about its own flags. So they are re-reported through `dom`, exactly the way
// `probe-node-connections` re-reports a hook's return value, and every one of
// the eight values the spec asserted by hand now compares clean against a
// running upstream.
//
// Held to the letter, the retirement could not have happened at all. Three
// things are red in `props` today and none of them is what the spec proved:
// `EdgeProps` and `EdgeComponentProps` are `left only`, and
// `ConnectionLineComponentProps` likewise — both were blocked on `edgeTypes`
// and `connectionLineComponent` not having crossed, which boundary stage 4
// (#62) has since done, leaving a fixture that sets one as the remaining half
// of each — and
// `NodeProps.width`/`height` differ as upstream's `0` against ps-flow's
// `undefined` on a node whose size nothing set — a divergence on the backlog
// (#22) that the retired spec **could not see**, because its own fixture gave
// both nodes explicit dimensions. Waiting for that section would have held a
// retirement on an instrument the assertions do not live in, and on two blockers
// neither of them is about.

import { SECTIONS } from "../trace-format.mjs";
import { defineScenario } from "../harness/scenario.mjs";
import { CorpusError, routeOf } from "./routes.mjs";
import { RESERVED } from "./reserved.mjs";

const CHROME_DEFAULTS = routeOf("./flow/chrome-defaults.ts");
const PROPS_RECORD = routeOf("./nodes/props-record.ts");

const PANE_SELECTOR = ".react-flow__pane";
const MINIMAP_SELECTOR = ".react-flow__minimap";

const node = (id) => `.react-flow__node[data-id="${id}"]`;

// `handleAt`, never `handle`. `test-debt.mjs` has a `handle(nodeId, handleId)`
// of the same arity that aims at `data-handleid`, and the two sources rebuild
// their selectors separately on purpose — a selector one of them re-aims must
// not silently re-aim the other. Two builders of one name and one arity meaning
// different attributes is how that decision turns into a trap, so this one says
// in its name which attribute it reads. The retired assertions located handles
// by side, because the smoke page's nodes carry no handle ids.
const handleAt = (nodeId, position) =>
  `.react-flow__handle[data-nodeid="${nodeId}"][data-handlepos="${position}"]`;

const retirementDebt = [
  // ── the chrome components, on their own defaults ─────────────────────────

  // Retires `MiniMap renders and is clickable`. The assertion clicked the
  // minimap fifty pixels in from its corner and asserted nothing about what
  // followed, which was the whole of its weakness: a default `MiniMap` is
  // neither `pannable` nor `zoomable`, so the interesting claim is that the
  // click moved *nothing*, and an assertion that looks at nothing cannot make
  // it. Here the click is the stimulus and the settled viewport is compared.
  {
    id: "minimap-default-click",
    route: CHROME_DEFAULTS,
    async run(a) {
      await a.click({ target: MINIMAP_SELECTOR, origin: "topLeft", dx: 50, dy: 50 });
    },
  },

  // Retires `Controls render and clicking zoom-in changes the transform`. All
  // three of the buttons the assertion located are pressed, not only the one it
  // clicked: it asserted the other two were visible and then left them alone,
  // so a fit-view button wired to zoom out would have passed it. The order is
  // the assertion's — zoom in, then the two it never pressed.
  //
  // `controls-horizontal` drives the same buttons on `chrome/controls.ts`, and
  // the two are not one scenario: that fixture exists to lay the buttons out
  // horizontally (#5153), and a separator inserted at the wrong point is a claim
  // about the horizontal list. This one is the vertical default, which no other
  // ps-flow fixture renders.
  {
    id: "controls-default-zoom",
    route: CHROME_DEFAULTS,
    async run(a) {
      await a.click(".react-flow__controls-zoomin");
      await a.click(".react-flow__controls-zoomout");
      await a.click(".react-flow__controls-fitview");
    },
  },

  // ── the viewport, from the identity transform ────────────────────────────

  // Retires `wheel-zoom changes the viewport transform`. The seed's
  // `wheel-zooms-the-pane` drives the same primitive against upstream's
  // `pane/general.ts`, which sets `minZoom` and `maxZoom` and fits its view: the
  // zoom it measures starts from whatever `fitView` computed. This one starts
  // from the identity, so the transform after it is the wheel's own arithmetic
  // and nothing else — which is the reading the assertion took, and the only one
  // it could take cheaply.
  {
    id: "wheel-zoom-from-identity-viewport",
    route: CHROME_DEFAULTS,
    async run(a) {
      await a.wheel(PANE_SELECTOR, { deltaY: -200 });
    },
  },

  // Retires `background drag pans the viewport`. **Completes the gesture**,
  // where the seed's `drag-pans-the-pane` settles mid-pan because upstream's own
  // spec never releases. Both readings matter and neither implies the other: a
  // pan applied on release and a pan applied per move look identical once the
  // pointer is up, and identical mid-gesture only if both sides also agree about
  // the end.
  {
    id: "pane-drag-from-identity-viewport",
    route: CHROME_DEFAULTS,
    async run(a) {
      await a.pan({ dx: 100, dy: 50, steps: 10 });
    },
  },

  // ── the only callback assertion either surface had ───────────────────────

  // Retires `node drag fires onNodesChange`, and it is the retirement the
  // per-test record exists for. The assertion read a count and an array length
  // off `window`, deliberately avoiding the change shape — it said so, in the
  // comment above it — because there was nothing to check a shape against. The
  // `callbacks` section compares the exact sequence with its arguments against
  // upstream's, so "at least one change happened" becomes every change, in
  // order, with its payload.
  //
  // The grab lands at client (50, 20), which is the smoke page's geometry
  // unchanged — `n1` at the flow origin, 100×40, under the identity viewport —
  // and it puts the press **inside the autopan band**, twenty pixels from the
  // top of the pane. That is not incidental and it is not a mistake: both sides
  // pan while the drag runs, and it is where this scenario's first findings
  // are. ps-flow fires `onSelectionDrag` and `onEdgesChange` where upstream
  // fires neither, fires no `onMoveStart` where upstream fires three, and does
  // not reproduce its own frame count across its two captures where upstream
  // does. The assertion that counted one array could not have seen any of it.
  {
    id: "drag-node-reports-changes",
    route: CHROME_DEFAULTS,
    async run(a) {
      await a.dragNode(node("n1"), { dx: 50, dy: 50, steps: 10 });
    },
  },

  // ── connections ──────────────────────────────────────────────────────────

  // Retires `click-connect creates an edge`. The direction is the assertion's
  // and it is load-bearing: the store dedupes an identical source/target pair,
  // so connecting `n1 → n2` again would silently no-op and the edge count would
  // stay at one whatever either implementation did. `n2.source → n1.target` is
  // the reverse of the seeded edge, and is a connection both sides have to make.
  //
  // `connectOnClick` is left at upstream's default rather than pinned by the
  // fixture, so this compares the default as well as the interaction.
  {
    id: "click-connect-reverse-direction",
    route: CHROME_DEFAULTS,
    async run(a) {
      await a.click(handleAt("n2", "right"));
      await a.click(handleAt("n1", "left"));
    },
  },

  // Retires the first half of `connection-state classes flip during drag`.
  // **Ends mid-gesture**, and has to: `connectingfrom` exists only while the
  // pointer is down, and the assertion had to interleave an `expect` with the
  // driving to see it. A scenario cannot interleave anything — it settles once,
  // at the end — so the half of the claim that is about a held pointer is its
  // own scenario, and the half about the release is the next one.
  {
    id: "connect-drag-holding-source",
    route: CHROME_DEFAULTS,
    async run(a) {
      await a.pointerDown(handleAt("n1", "right"));
      await a.pointerMove(null, { dx: 40, dy: 20 });
      await a.pointerMove(null, { dx: 40, dy: 20 });
    },
  },

  // Retires the second half: the class is gone once the drag is dropped. The
  // release lands on the pane rather than on a handle, so no edge is created and
  // what is compared is a flow that has returned to rest — the state the
  // assertion checked, and the one a class that failed to clear would differ in.
  {
    id: "connect-drag-released-on-pane",
    route: CHROME_DEFAULTS,
    async run(a) {
      await a.pointerDown(handleAt("n1", "right"));
      await a.pointerMove(null, { dx: 40, dy: 20 });
      await a.pointerMove(null, { dx: 40, dy: 20 });
      await a.pointerUp(null);
    },
  },

  // ── the NodeProps record ─────────────────────────────────────────────────

  // Retires both of `node-props.spec.ts`'s tests at once, because one fixture
  // holds both branches and both of its nodes render their own reading: the
  // child's explicit `false` flags, its `parentId` and its absolute position,
  // and the parent's three defaulted flags beside them.
  //
  // Driven rather than mounted, though the retired spec only ever read a static
  // render. The parent is selectable and the child is not, so the two clicks
  // re-render both nodes through a selection change the child must not take part
  // in — the record is compared once as the mount produced it, and once after
  // the store has had something to say about it.
  {
    id: "node-props-record-parented",
    route: PROPS_RECORD,
    async run(a) {
      await a.click(node("props-parent"));
      await a.click(node("props-child"));
    },
  },
];

/**
 * The per-test record of what retired and what replaced it.
 *
 * **Per test, not per file**, because the eight assertions in `smoke.spec.ts`
 * were eight different claims and one of them was the only callback assertion
 * the repo had. `test` is the exact title; `scenarios` are cited by name and
 * resolved against the corpus by `assertRetirementsResolve`; and
 * `retiredTestProblems` holds the spec sources to the titles — a retirement
 * whose test is still in the file has not happened, and a retired title that
 * quietly came back would be two gates asserting one thing with only one of them
 * written down.
 *
 * `section` is the **trace section the re-report lands in**, and it is the field
 * that keeps the substitution above from living only in prose. A citation that
 * resolves says a scenario exists; this says where that scenario does the work,
 * and `retirement-debt.test.mjs` reads the stored traces to check the section is
 * not empty on either side. A scenario that stopped observing what it was
 * written to observe would otherwise keep satisfying the register by name.
 */
export const RETIREMENTS = Object.freeze(
  [
    {
      spec: "smoke.spec.ts",
      test: "Background renders behind the flow",
      proved: "a default Background renders inside a mounted flow",
      section: "dom",
      scenarios: ["mount-baseline--flow-chrome-defaults"],
    },
    {
      spec: "smoke.spec.ts",
      test: "MiniMap renders and is clickable",
      proved: "a default MiniMap renders and survives being clicked",
      section: "dom",
      scenarios: ["minimap-default-click"],
    },
    {
      spec: "smoke.spec.ts",
      test: "Controls render and clicking zoom-in changes the transform",
      proved: "the three default Controls buttons render, and zoom-in moves the viewport",
      section: "dom",
      scenarios: ["controls-default-zoom"],
    },
    {
      spec: "smoke.spec.ts",
      test: "wheel-zoom changes the viewport transform",
      proved: "a wheel over the pane changes the viewport transform",
      section: "dom",
      scenarios: ["wheel-zoom-from-identity-viewport"],
    },
    {
      spec: "smoke.spec.ts",
      test: "background drag pans the viewport",
      proved: "a completed pointer drag on the pane changes the viewport transform",
      section: "dom",
      scenarios: ["pane-drag-from-identity-viewport"],
    },
    {
      spec: "smoke.spec.ts",
      test: "node drag fires onNodesChange",
      proved: "dragging a node calls onNodesChange with a non-empty change array",
      section: "callbacks",
      scenarios: ["drag-node-reports-changes"],
    },
    {
      spec: "smoke.spec.ts",
      test: "click-connect creates an edge",
      proved: "clicking a source handle and then a target handle adds an edge",
      section: "dom",
      scenarios: ["click-connect-reverse-direction"],
    },
    {
      spec: "smoke.spec.ts",
      test: "connection-state classes flip during drag",
      proved:
        "connectingfrom is on the source handle while a connection is dragged, and gone after the drop",
      section: "dom",
      scenarios: ["connect-drag-holding-source", "connect-drag-released-on-pane"],
    },
    {
      spec: "node-props.spec.ts",
      test: "threads explicit flags, dimensions, parentId and absolute position",
      proved:
        "a parented node's NodeProps carries its explicit flags, its measured size, its parentId and its absolute position",
      section: "dom",
      scenarios: ["node-props-record-parented"],
    },
    {
      spec: "node-props.spec.ts",
      test: "defaults unset flags from the flow-level props",
      proved: "a node that sets none of the three flags takes them from the flow-level props",
      section: "dom",
      scenarios: ["node-props-record-parented"],
    },
  ].map(Object.freeze)
);

/**
 * The retirements the spec sources they name do not honour.
 *
 * `specSource(spec)` returns the file's text, or `null` when the spec has been
 * removed altogether — which is how `node-props.spec.ts` retires, both of its
 * tests being here and a file with nothing left in it not being a suite. A spec
 * that still holds a retired title is the failure this exists for: the
 * retirement is recorded, the scenario is written, and the hand-authored
 * assertion is running beside it.
 *
 * What is looked for is the **`test(` call**, not the title as text. The
 * surviving spec's own header names several of the retired tests while saying
 * what happened to them, and a register that could not tell an explanation from
 * a live assertion would make writing the explanation the thing that failed.
 */
const testCall = (title) =>
  new RegExp(String.raw`\btest\s*\(\s*(['"\`])${title.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\1`);

export const retiredTestProblems = (specSource) => {
  const problems = [];

  for (const { spec, test } of RETIREMENTS) {
    const source = specSource(spec);
    if (source === null || source === undefined) continue;
    if (testCall(test).test(source)) {
      problems.push(
        `${spec} still holds the retired test "${test}" — the retirement is recorded and its ` +
          `scenario is written, so the hand-authored assertion is running beside the net.`
      );
    }
  }

  return problems;
};

/**
 * The two tests that did **not** retire, and what each was called before.
 *
 * Here rather than only in the spec because the register's claim is "no coverage
 * is lost", and that is checkable per test only if every one of the original ten
 * titles is accounted for. Eight are in `RETIREMENTS`; without these two an
 * auditor diffing the old file against the register finds a title that is
 * neither retired nor present, and cannot tell a rename from a deletion.
 *
 * `was` is the old title and `test` the current one. The mount test was renamed
 * because `two nodes and one edge render` describes what it looks at, where what
 * it is *for* is that the page came up at all — the counts are how a mount that
 * threw half way is told from one that worked. The console session kept its
 * name; `was` is written out for it all the same, so the pair reads as a table
 * rather than as one entry with an exception beside it.
 */
export const LIVENESS = Object.freeze(
  [
    {
      spec: "smoke.spec.ts",
      was: "two nodes and one edge render",
      test: "the driver page mounts and renders its fixture",
    },
    {
      spec: "smoke.spec.ts",
      was: "no console errors during a 5-second interaction session",
      test: "no console errors during a 5-second interaction session",
    },
  ].map(Object.freeze)
);

/**
 * Every scenario a **retirement** names has to be one the corpus holds.
 *
 * A citation that resolves to nothing is how the handover silently fails to
 * happen: the assertion is deleted, the register says a scenario replaced it,
 * and the name is a typo or a scenario somebody renamed afterwards. Exactly the
 * hazard `reserved.mjs` exists for one source along, and answered the same way.
 *
 * It is handed the corpus rather than reading one, because only the assembled
 * corpus knows every name there is and this module cannot see it — `../net.mjs`
 * is where the two meet. Checked against the ids the corpus actually holds,
 * never the wider **name space** the changelog audit resolves against: a
 * reserved id promises a scenario and drives nothing, which is a legitimate
 * state for a plan and never one for a retirement, since an assertion has
 * already been deleted by the time this is asked.
 */
export const assertRetirementsResolve = (scenarios) => {
  const held = new Set(scenarios.map((scenario) => scenario.id));
  const dangling = RETIREMENTS.flatMap(({ spec, test, scenarios: cited }) =>
    cited.filter((id) => !held.has(id)).map((id) => `  ${spec} — ${test}: ${id}`)
  );

  if (dangling.length) {
    throw new CorpusError(
      `${dangling.length} retirement citation(s) name a scenario the corpus does not hold:\n` +
        dangling.join("\n") +
        `\nThe assertion each one replaced has already been deleted, so a name that resolves to ` +
        `nothing is coverage the repo believes it has and does not.`
    );
  }

  return scenarios;
};

// The two halves have to name each other. A scenario here that no retirement
// cites is a scenario in the wrong source — the retirement debt is *defined* by
// what it retires, and one written for its own sake belongs with the
// hole-closing scenarios. A retirement citing nothing has retired an assertion
// into thin air, and one naming a section the trace format does not have has
// recorded where its re-report lands in a word nothing can check.
const cited = new Set(RETIREMENTS.flatMap(({ scenarios }) => scenarios));
const written = retirementDebt.map(({ id }) => id);
const uncited = written.filter((id) => !cited.has(id));
const reserved = written.filter((id) => id in RESERVED);
const empty = RETIREMENTS.filter(({ scenarios }) => scenarios.length === 0);
const unknownSection = RETIREMENTS.filter(({ section }) => !SECTIONS.includes(section));

if (uncited.length || reserved.length || empty.length || unknownSection.length) {
  throw new CorpusError(
    `the retirement debt does not line up with the retirements it was written for:\n` +
      (uncited.length ? `  written and cited by no retirement: ${uncited.join(", ")}\n` : "") +
      (reserved.length ? `  taking an id reserved for a test-debt scenario: ${reserved.join(", ")}\n` : "") +
      (empty.length ? `  retiring with no scenario named: ${empty.map(({ test }) => test).join(", ")}\n` : "") +
      (unknownSection.length
        ? `  retiring into no section of the trace: ${unknownSection.map(({ test }) => test).join(", ")}\n`
        : "")
  );
}

/** The retirement-debt scenarios, in the order `RETIREMENTS` retires against them. */
export const retirementDebtScenarios = retirementDebt.map(defineScenario);
