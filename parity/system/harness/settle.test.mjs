import { test } from "node:test";
import assert from "node:assert/strict";

import { EMPTY_DOM, createFakePort } from "./fake-port.mjs";
import { SettleError, settleDom } from "./settle.mjs";

const ROOT = ".react-flow";

const flow = (label) => ({ page: EMPTY_DOM.page, root: { tag: "div", attrs: { "data-x": label }, children: [] } });

// The definition, stated as a test: settled is two consecutive snapshots
// agreeing, not a duration that expired.
test("a page that is already still settles as soon as two snapshots agree", async () => {
  const { port, ticks } = createFakePort({ dom: flow("a") });

  assert.deepEqual(await settleDom(port, ROOT), flow("a"));
  assert.equal(ticks(), 1);
});

test("a page still changing is polled until it stops, and the settled snapshot is what comes back", async () => {
  const { port, ticks } = createFakePort({ dom: [flow("mounting"), flow("measured"), flow("fitted"), flow("fitted")] });

  assert.deepEqual(await settleDom(port, ROOT), flow("fitted"));
  assert.equal(ticks(), 3);
});

// The snapshot returned is the one that agreed, never a fresh read afterwards.
// A page can change again the instant after it settled, and a capture that
// re-read would record something no poll ever observed to be stable.
test("the snapshot returned is the one that agreed, not a later read", async () => {
  const { port } = createFakePort({ dom: [flow("a"), flow("a"), flow("moved-again")] });

  assert.deepEqual(await settleDom(port, ROOT), flow("a"));
});

// Two frames apart is a weak claim on a page whose work lands in bursts. Asking
// for more agreements is how a scenario buys a stronger one, and the count is
// the whole of the difference.
test("more agreements means more consecutive polls have to agree", async () => {
  const { port } = createFakePort({ dom: [flow("a"), flow("a"), flow("b"), flow("b"), flow("b")] });

  assert.deepEqual(await settleDom(port, ROOT, { agreements: 3 }), flow("b"));
});

// One observation cannot establish that anything stopped changing, and an
// `agreements: 1` settle is a capture that never waited wearing the word.
test("settling on a single snapshot is refused rather than quietly accepted", async () => {
  const { port } = createFakePort({ dom: flow("a") });

  await assert.rejects(() => settleDom(port, ROOT, { agreements: 1 }), SettleError);
  await assert.rejects(() => settleDom(port, ROOT, { agreements: 2.5 }), SettleError);
});

// The alternative to throwing is capturing a snapshot known to be mid-flight,
// which is a fixed timeout wearing a different hat: the run would go on and
// report a divergence in every section at once.
test("a page that never stops changing is a person's problem, not a longer wait", async () => {
  let poll = 0;
  const port = {
    async dom() {
      return flow(`poll-${poll++}`);
    },
    async tick() {},
  };

  await assert.rejects(() => settleDom(port, ROOT, { polls: 5 }), (e) => {
    assert.ok(e instanceof SettleError);
    assert.equal(e.polls, 5);
    // The two that were still disagreeing, so a reader has something to diff.
    assert.notDeepEqual(e.previous, e.latest);
    return true;
  });
});

// `root: null` is what an unmounted page answers, and it settles like any other
// stable observation — a side that never rendered a flow is a finding for the
// comparison to read, not a capture that hangs until a ceiling.
test("a page with no flow on it settles immediately, at null", async () => {
  const { port } = createFakePort();

  assert.deepEqual(await settleDom(port, ROOT), EMPTY_DOM);
});

// Page-level state is part of the section, so it is part of what has to hold
// still: a flow that has stopped moving on a page that is still scrolling has
// not settled.
test("page-level state is settled on too, not only the element tree", async () => {
  const scrolling = (scrollY) => ({ page: { scrollX: 0, scrollY, visualViewportScale: 1 }, root: null });
  const { port, ticks } = createFakePort({ dom: [scrolling(0), scrolling(20), scrolling(40), scrolling(40)] });

  assert.deepEqual(await settleDom(port, ROOT), scrolling(40));
  assert.equal(ticks(), 3);
});
