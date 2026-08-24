// Running one scenario against one side, and the trace that comes out (#35).
//
// The **capture** half of the net. Its counterpart, **compare**, reads two
// stored traces and reports what differs; they are deliberately separate steps,
// so that capture records everything observable and everything the noise policy
// forgives lives downstream. See `../README.md`.
//
// Both sides load **the same page**, `parity/driver/index.html`, differing only
// in the `?side=` parameter that decides which bundle it imports — the other
// parameter the net asks for, `?observe=callbacks`, is identical on both.
// Upstream's own vendored app is vite plus a path router where this is a static
// server plus a hash router, and it wraps the flow in different container
// markup — which is not cosmetic, because the container's box feeds `fitView`,
// which feeds the viewport transform, which feeds everything.

import { DRIVER_PAGE, SIDES } from "../../driver/sides.mjs";
import { TRACE_FORMAT, validateTrace } from "../trace-format.mjs";
import { OBSERVE, callbacksSection } from "./call-log.mjs";
import { createDrivingLog } from "./driving.mjs";
import { assertPendingStillEmpty } from "./pending.mjs";
import { createPagePort } from "./port.mjs";
import { settleDom } from "./settle.mjs";
import { createVocabulary } from "./vocabulary.mjs";

// The flow's root element. It is what the mount waits for, and its box is the
// container measurement everything downstream is computed from.
export const FLOW_ROOT = ".react-flow";

// Semantic, never a sequence number: a gate cites scenarios by name, and
// numbers shift when the corpus is trimmed — delete one and either every
// reference moves or there is a permanent gap. `--` separates a scenario kind
// from the fixture it runs against (`mount-baseline--nodes-general`).
const SCENARIO_ID = /^[a-z][a-z0-9]*(-{1,2}[a-z0-9]+)*$/;
const SEQUENCE_ID = /^s?\d+$/i;

export class ScenarioError extends Error {
  constructor(message) {
    super(message);
    this.name = "ScenarioError";
  }
}

/**
 * A scenario is `{ id, route, run }` — a semantic id, the driver route it
 * mounts, and the function that drives it. `run` receives the action vocabulary
 * and nothing else.
 *
 * `touch: true` is a declared capability rather than something the `touch`
 * primitive turns on for itself: emulation has to be enabled before the
 * document loads, and enabling it for every scenario would narrow the whole net
 * to a touch-capable browser to serve the two scenarios that need one.
 */
export const defineScenario = ({ id, route, run, touch = false }) => {
  if (typeof id !== "string" || !SCENARIO_ID.test(id) || SEQUENCE_ID.test(id)) {
    throw new ScenarioError(
      `${JSON.stringify(id)} is not a scenario id — ids are semantic and kebab-cased ` +
        `(\`drag-node-release\`), never a sequence number, because a gate cites them by name.`
    );
  }
  if (typeof route !== "string" || !route.startsWith("/")) {
    throw new ScenarioError(`${id}: a route is the driver's hash path, starting with "/" — got ${JSON.stringify(route)}`);
  }
  if (typeof run !== "function") throw new ScenarioError(`${id}: a scenario needs a run function`);
  if (typeof touch !== "boolean") throw new ScenarioError(`${id}: touch is declared or it is not — got ${JSON.stringify(touch)}`);

  return Object.freeze({ id, route, run, touch });
};

/**
 * Relative, and resolved against the browser context's `baseURL`.
 *
 * Two parameters, and both are the net's rather than the page's: which bundle to
 * import, and that the fixture driver should wrap its callback props into the
 * call log. The second is asked for explicitly because installing a callback
 * prop changes what the page renders — `call-log.mjs`'s `OBSERVE` says how — and
 * the conformance suite drives this same page to measure upstream's fixture as
 * upstream wrote it. Neither parameter is reachable from a scenario.
 */
export const driverUrl = (route, side) =>
  `${DRIVER_PAGE}?side=${side}&${OBSERVE.param}=${OBSERVE.callbacks}#${route}`;

/**
 * Drives `scenario` against `side` and returns a validated trace.
 *
 * `page` is a Playwright page; only `on`, `off` and `goto` are used directly,
 * everything else going through the port, which is the seam the harness's own
 * tests replace. `settle` is passed through to `settleDom` — the poll ceiling
 * and how many consecutive snapshots have to agree.
 */
export const runScenario = async (
  page,
  scenario,
  {
    side,
    capture,
    baseline,
    mountTimeout = 10_000,
    resolveTimeout,
    settle = {},
    port = createPagePort(page, { resolveTimeout }),
  } = {}
) => {
  if (!SIDES.includes(side)) {
    throw new ScenarioError(`unknown side ${JSON.stringify(side)} — expected ${SIDES.join(" or ")}`);
  }
  if (!Number.isInteger(capture) || capture < 1) {
    throw new ScenarioError(`capture is which of a side's runs this is, counting from 1 — got ${JSON.stringify(capture)}`);
  }
  if (typeof baseline !== "string" || baseline === "") {
    throw new ScenarioError(`a trace records the vendored upstream version it was captured against; none was given`);
  }

  const log = createDrivingLog();
  const apiCalls = [];
  const consoleEntries = [];

  // Registered before the navigation, or the page's first words are lost. An
  // uncaught exception is not a console message to Playwright, but it is very
  // much something the page said, and it would otherwise be invisible in every
  // section at once.
  const onConsole = (message) => consoleEntries.push({ level: message.type(), text: message.text() });
  const onPageError = (error) => consoleEntries.push({ level: "pageerror", text: String(error?.message ?? error) });
  page.on("console", onConsole);
  page.on("pageerror", onPageError);

  try {
    // Before the navigation, and only for a scenario that asked: touch
    // emulation applied after the document has loaded leaves every dispatched
    // touch inert, and applied to every scenario it would make the whole net
    // measure a touch-capable browser.
    if (scenario.touch) await port.enableTouch();

    // Blank first, then the driver. A capture reuses the page, so the second
    // capture of a scenario navigates to the URL the page is *already* on — and
    // a navigation to the same document differing only in its fragment is a
    // same-document navigation: nothing reloads, React state survives, and
    // capture 2 starts wherever capture 1 left the flow. Self-consistency (#43)
    // caught it against a real page, where a drag's second capture resolved the
    // node 100px further right than its first.
    await page.goto("about:blank");

    // And the pointer parked, for the same reason one level down. The cursor
    // belongs to the browser rather than to the document, so it stays where the
    // previous capture left it — and the page that mounts under it fires its
    // boundary events from *there*: capture 2 of a drag recorded a
    // `onPaneMouseEnter` before the flow had finished mounting, carrying
    // coordinates a hundred pixels along, while capture 1 recorded it when the
    // drag first moved. Parked on `about:blank`, so no page sees the move, and
    // it is not a driving action: nothing was done to the flow, the same way
    // blanking the page is not one.
    //
    // And released, which is the same finding one step on. A scenario may end
    // **mid-gesture** — settling with the pointer still down is the only way
    // transient state is observable, and the conformance seed lifts a pane pan
    // that upstream's own spec never releases (#55) — and the *button* belongs
    // to the browser exactly as the cursor does, so it survives the blanking
    // too. Measured, on `drag-pans-the-pane`: without this line, upstream
    // disagreed with itself on three runs out of three, its second capture
    // recording `buttons: 1` and `pressure: 0.5` on the events its mount fired
    // where the first recorded `0` and `0`. Capture 2 was mounting under a
    // press capture 1 had left held. Releasing a button nobody pressed is
    // dispatched all the same and seen by nothing, here on a blank page.
    await port.mouse("move", { x: -1, y: -1 });
    await port.mouse("up", { x: -1, y: -1 });

    await page.goto(driverUrl(scenario.route, side));

    // Waited for, then settled, then measured. Each side waits on its own clock
    // — polling until consecutive snapshots agree, never a duration — because
    // selectors resolve against each side's own render, and anything aimed at a
    // flow still mounting is aimed at a layout about to move. The measurement is
    // taken afterwards for the same reason: it is the container box `fitView` is
    // computed from, and it lands in the one section that carries no tolerance.
    const appeared = await port.box(FLOW_ROOT, { timeout: mountTimeout });
    if (appeared) await settleDom(port, FLOW_ROOT, settle);
    const box = appeared ? await port.box(FLOW_ROOT) : null;

    // The mount is a driving action like any other, and recorded as one. A side
    // that never renders a flow then reads as an unresolved first action —
    // followed by a scenario whose every action is also unresolved — instead of
    // as a thrown timeout, which reads as a flake.
    log.record(
      box
        ? { action: "mount", target: FLOW_ROOT, resolved: true, box, dispatched: { route: scenario.route } }
        : { action: "mount", target: FLOW_ROOT, resolved: false }
    );

    // The vocabulary, and nothing else. No page, no side, no library handle.
    await scenario.run(createVocabulary(port, log, apiCalls));

    // And settled again before it is read. This snapshot *is* the `dom`
    // section — the one two consecutive polls agreed on, never a fresh read
    // afterwards — so nothing reaches the trace that was not observed to be
    // stable. Note that settled is not **gesture complete**: a scenario whose
    // last action leaves the pointer down settles mid-gesture, which is the
    // only way transient state is observable at all.
    //
    // The `callbacks` section is read here too, and after the settle rather
    // than before it: a handler the page had not got round to firing yet is a
    // call the scenario made happen, and the log is read as a section of the
    // same end-state snapshot precisely so that no mid-interaction checkpoint
    // is needed to see it. Nothing accumulates during the read — the
    // serialization already happened, once per call, at the moment of the call.
    const sections = {
      dom: await settleDom(port, FLOW_ROOT, settle),
      callbacks: callbacksSection(await port.callbacks()),
      hooks: {},
      api: { queries: {}, calls: apiCalls },
      props: {},
      console: consoleEntries,
      driving: log.entries(),
    };

    // The four sections above that are empty are empty because their capture is
    // not built, and each is declared in `pending.mjs`. This is what stops one
    // from being quietly filled in without the declaration going with it.
    assertPendingStillEmpty(sections);

    return validateTrace(
      { traceFormat: TRACE_FORMAT, scenario: scenario.id, side, capture, baseline, sections },
      `${scenario.id} (${side}, capture ${capture})`
    );
  } finally {
    // A page is reused across captures, and a listener left behind would file
    // the first capture's console output under the second.
    page.off("console", onConsole);
    page.off("pageerror", onPageError);
  }
};
