// Running one scenario against one side, and the trace that comes out (#35).
//
// The **capture** half of the net. Its counterpart, **compare**, reads two
// stored traces and reports what differs; they are deliberately separate steps,
// so that capture records everything observable and everything the noise policy
// forgives lives downstream. See `../README.md`.
//
// Both sides load **the same page**, `parity/driver/index.html`, differing only
// in the `?side=` parameter that decides which bundle it imports. Upstream's own
// vendored app is vite plus a path router where this is a static server plus a
// hash router, and it wraps the flow in different container markup — which is
// not cosmetic, because the container's box feeds `fitView`, which feeds the
// viewport transform, which feeds everything.

import { DRIVER_PAGE, SIDES } from "../../driver/sides.mjs";
import { TRACE_FORMAT, validateTrace } from "../trace-format.mjs";
import { createDrivingLog } from "./driving.mjs";
import { assertPendingStillEmpty } from "./pending.mjs";
import { createPagePort } from "./port.mjs";
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

/** Relative, and resolved against the browser context's `baseURL`. */
export const driverUrl = (route, side) => `${DRIVER_PAGE}?side=${side}#${route}`;

/**
 * Drives `scenario` against `side` and returns a validated trace.
 *
 * `page` is a Playwright page; only `on`, `off` and `goto` are used directly,
 * everything else going through the port, which is the seam the harness's own
 * tests replace.
 */
export const runScenario = async (
  page,
  scenario,
  { side, capture, baseline, mountTimeout = 10_000, resolveTimeout, port = createPagePort(page, { resolveTimeout }) } = {}
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
    await page.goto(driverUrl(scenario.route, side));

    // The mount is a driving action like any other, and recorded as one. A side
    // that never renders a flow then reads as an unresolved first action —
    // followed by a scenario whose every action is also unresolved — instead of
    // as a thrown timeout, which reads as a flake. The box it resolves to is the
    // container measurement `fitView` is computed from, so it belongs in the
    // section that carries no tolerance.
    const box = await port.box(FLOW_ROOT, { timeout: mountTimeout });
    log.record(
      box
        ? { action: "mount", target: FLOW_ROOT, resolved: true, box, dispatched: { route: scenario.route } }
        : { action: "mount", target: FLOW_ROOT, resolved: false }
    );

    // The vocabulary, and nothing else. No page, no side, no library handle.
    await scenario.run(createVocabulary(port, log, apiCalls));

    const sections = {
      dom: { page: await port.pageState(), root: null },
      callbacks: [],
      hooks: {},
      api: { queries: {}, calls: apiCalls },
      props: {},
      console: consoleEntries,
      driving: log.entries(),
    };

    // The five sections above that are empty are empty because their capture is
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
