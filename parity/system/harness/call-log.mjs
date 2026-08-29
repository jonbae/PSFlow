// The in-page call log — the `callbacks` section's capture (#54).
//
// The second half of a mechanism whose comparison landed first (#44): calls are
// compared as an **exact sequence**, and this is what produces the sequence.
//
// ## Why the log is in the page at all
//
// Callbacks **leave no residue in end state**. If ps-flow never fires a handler
// the DOM is identical, every other section agrees, and an end-state net passes
// green — which is precisely why the boundary staging crossed them first (#52).
// So the one section whose absence is invisible needs an observation the other
// six do not: the calls have to be caught *as they happen* and kept somewhere
// the end-state snapshot can read.
//
// That somewhere is this log, and it is read as one more section of the same
// snapshot rather than by checkpointing mid-interaction. The one-snapshot-per-
// test rule survives, and a handler that never fired is still a finding.
//
// ## Why the arguments are serialized at the moment of the call
//
// Not at the end, and this is not an optimisation. xyflow hands a handler live
// objects it goes on to **mutate** — a node's `position` during a drag, a
// connection state as the pointer moves — and a synthetic event whose fields
// are gone by the time the page settles. A log holding references would record
// the end state of every argument it was ever handed, which is the one thing
// the other six sections already say. `serialize.mjs` is what it records with,
// and it is why that module imports nothing and runs in the page.
//
// ## Failing to serialize is a question for a person
//
// `serializeValue` throws on a graph past its depth ceiling rather than
// truncating it, because a truncation marker would put two different subgraphs
// under one value and make them compare equal. In the page that throw would land
// inside a React event handler, where it becomes a `pageerror` in the `console`
// section at best and a swallowed exception at worst — so the log catches it,
// records what failed, and the **harness** raises it when it reads the log. A
// scenario that could not record one call is not a scenario with one fewer call
// in it: the sequence is what is being compared, so a gap in it invalidates the
// whole section.
//
// ## Runs in the page
//
// Like `dom.mjs` and `serialize.mjs`. Unlike `dom.mjs`, it is not handed to
// `page.evaluate` as source — it is bundled into the driver (`parity/driver/`),
// which is why it may import `serialize.mjs` normally. What `page.evaluate`
// does reach is `read()`, through the global below.

import { serializeCall } from "./serialize.mjs";

/**
 * Where the driver page publishes its log, and the only name the harness and
 * the driver share. `port.mjs` passes it into the page rather than closing over
 * it, since an evaluated function arrives as source with no scope.
 */
export const CALL_LOG = "__psflowCalls";

/**
 * The page parameter that turns the wrapping on — `?observe=callbacks`, the
 * second thing after `?side=` that a URL says about a driver page.
 *
 * **Observing is the net's, not the page's.** Installing a callback prop is not
 * free: three of upstream's are *presence*-sensitive rather than return-value
 * sensitive, and `onReconnect` is the loud one — passing it at all renders a
 * reconnect anchor per edge endpoint, twenty-two elements in the edges fixture
 * that the fixture never asked for. Symmetric across the two sides, so the net
 * is unharmed; but the **conformance test suite** drives this same page, and
 * what it is for is upstream's *asserted intent* against upstream's own
 * unmodified fixture. A spec failing because the driver had quietly added props
 * would be blamed on ps-flow, which is the misattribution everything here is
 * built to prevent.
 *
 * So the fixture renders as its author wrote it, and the net asks for the
 * observed form explicitly. Forgetting to ask is not left to discipline: the
 * driver reports what it wrapped, and a capture whose fixture driver wrapped
 * **nothing** fails — see `callbacksSection`.
 */
export const OBSERVE = { param: "observe", callbacks: "callbacks" };

export class CallLogError extends Error {
  constructor(message) {
    super(message);
    this.name = "CallLogError";
  }
}

/**
 * A log, and the wrapper that feeds it.
 *
 * `maxDepth` is `serializeValue`'s ceiling, passed through so a test can reach
 * it without building a sixteen-deep object.
 */
export const createCallLog = ({ maxDepth } = {}) => {
  const entries = [];
  const failures = [];

  // What the fixture driver wrapped, and `null` until one mounts at all. The
  // three states are different findings: `null` is a route with no fixture
  // driver on it (a directly-mounted component, which has no props to wrap),
  // `[]` is a fixture driver that wrapped nothing — the page was loaded without
  // `?observe=callbacks` — and a list is the props this page can report calls
  // for. Only the middle one is a fault, and it is the one that would otherwise
  // pass silently: an empty section on both sides.
  let observing = null;

  /**
   * Records one call. The serialization happens **before** the handler beneath
   * runs, for two reasons that point the same way: the arguments are what they
   * were when the library made the call, and a handler that causes further
   * calls — `onNodesChange` driving a `setState` that fires another — leaves
   * them in the order the library made them.
   */
  const record = (name, args, metadata = {}) => {
    try {
      entries.push({ ...serializeCall(name, args, { maxDepth }), ...metadata });
    } catch (e) {
      // Deliberately not rethrown here. Throwing inside a library's own event
      // dispatch changes what the page does — which is the one thing an
      // observer must not do — and the failure is louder read back through the
      // harness than it is as a `pageerror` among the console entries.
      failures.push({ name, index: entries.length, error: String(e?.message ?? e) });
    }
  };

  return {
    record,

    /**
     * A hook option callback is still recorded exactly — every call, in the
     * order it happened. The marker lets the probe comparison select these
     * receipts without mixing in ordinary flow callbacks caused by replacing
     * a graph type; it changes no count, order, arguments, or interleaving.
     */
    wrapProbe(name) {
      return (...args) => record(name, args, { probe: true });
    },

    /**
     * Declares which callback props a mounted fixture driver wrapped. Called on
     * every mount, with an empty list when observation was not asked for — a
     * driver that reported nothing at all would be indistinguishable from a
     * route that has no driver on it, and the harness could not tell an
     * unobserved run from a legitimately quiet one.
     */
    observe(names) {
      observing = [...names];
    },

    /**
     * The observed form of one handler: it records the call and then defers
     * entirely to `handler`, returning what it returns.
     *
     * `unhandled` is what to answer when there is no handler beneath — the
     * driver installs every callback prop upstream declares, including the ones
     * no fixture sets, and for two of them *absent* and *present returning
     * undefined* are different instructions to the library. The register lives
     * with the derivation, in `parity/driver/callbacks.mjs`; here it is one
     * value.
     */
    wrap(name, handler, unhandled = undefined) {
      return (...args) => {
        record(name, args);
        return typeof handler === "function" ? handler(...args) : unhandled;
      };
    },

    /**
     * What the harness reads through `page.evaluate`. Plain JSON — everything
     * that could not cross that boundary was turned into a marker by
     * `serialize.mjs` at the moment of the call.
     */
    read() {
      return {
        entries: entries.slice(),
        failures: failures.slice(),
        observing: observing && [...observing],
      };
    },
  };
};

/**
 * Publishes a log on `target` (the page's `window`) and returns it, or returns
 * the one already there. Idempotent because two places install it and neither
 * can be the only one: the page's entry point, so that *every* route answers
 * the harness rather than only the ones that mount a flow, and the driver
 * component, which needs the same log to wrap handlers into.
 */
export const installCallLog = (target, options) => {
  if (!target[CALL_LOG]) target[CALL_LOG] = createCallLog(options);
  return target[CALL_LOG];
};

/**
 * Turns what the page answered into the trace's `callbacks` section, or throws.
 *
 * Three failures, and all three are the same kind of thing — the section would
 * otherwise be *empty and meaningless*, which compares clean against an equally
 * empty one on the other side. That is the failure this whole effort exists to
 * remove, and it is why an absent log is not treated the way an absent
 * imperative bridge is (recorded as unresolved and driven past): the bridge is
 * legitimately missing until it crosses, while a driver bundle with no log in
 * it is a stale bundle.
 */
export const callbacksSection = ({ installed, entries, failures, observing }) => {
  if (installed && Array.isArray(observing) && observing.length === 0) {
    throw new CallLogError(
      `the page mounted a fixture driver that wrapped no callback props, so nothing it did could ` +
        `have been recorded. The URL was missing \`?${OBSERVE.param}=${OBSERVE.callbacks}\` — the net ` +
        `asks for the observed form explicitly, because installing a callback prop changes what the ` +
        `page renders and the conformance suite drives this same page. \`driverUrl\` in ` +
        `\`scenario.mjs\` is what adds it.`
    );
  }
  if (!installed) {
    throw new CallLogError(
      `the page published no call log at \`window.${CALL_LOG}\`. The driver bundle it loaded ` +
        `predates the log — rebuild it with \`npm run build:driver\`. Capturing anyway would ` +
        `record an empty \`callbacks\` section, which compares clean against the other side's ` +
        `equally empty one and proves nothing.`
    );
  }
  if (failures.length) {
    throw new CallLogError(
      `${failures.length} call${failures.length === 1 ? "" : "s"} could not be serialized:\n` +
        failures.map((f) => `  - ${f.name} (would have been callbacks/${f.index}): ${f.error}`).join("\n") +
        `\nThe section is compared as an exact sequence, so a call missing from it is not a shorter ` +
        `sequence — it is an unreadable one.`
    );
  }
  return entries;
};
