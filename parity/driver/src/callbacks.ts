// Wiring the driver's handlers into the in-page call log (#54).
//
// The log itself is the harness's — `parity/system/harness/call-log.mjs`, one of
// the three modules that run **in the page** rather than driving one from
// outside. This is the driver's half: it publishes the log on `window` so the
// harness can read it back, and it turns a fixture's props into the observed
// handlers `Flow.tsx` hands to `<ReactFlow />`.
//
// It is a separate file so that `Flow.tsx` stays a twin of upstream's, line for
// line, which is what makes a driver difference impossible to mistake for a
// library difference.
//
// **Every callback prop upstream declares is installed**, not only the ones the
// fixture set. A handler nobody passes is a handler that fires on neither side,
// so the two traces agree and the section says nothing — and callbacks are the
// one class of behaviour with no other witness. Which props those are is derived
// from the vendored `ReactFlowProps` at build time and injected as
// `psflow:callbacks`; see `../callbacks.mjs` for why it is derived and what the
// two registers in it hold.

import { useMemo } from 'react';

import { OBSERVE, installCallLog } from '../../system/harness/call-log.mjs';
import manifest from 'psflow:callbacks';

type Handler = (...args: unknown[]) => unknown;
type Props = Record<string, unknown>;

/**
 * Publishes the log on `window`, and is called by the page's entry point rather
 * than only by the driver component: **every** route has to answer the harness,
 * including the directly-mounted components that never render a flow. A route
 * with no log would be indistinguishable from a driver bundle built before the
 * log existed, and capture treats that as the stale bundle it usually is.
 */
export const publishCallLog = () => installCallLog(window);

/** `?observe=callbacks` — the net asks; nothing else does. `call-log.mjs` says why. */
const observationAsked = () =>
  new URLSearchParams(window.location.search).get(OBSERVE.param) === OBSERVE.callbacks;

/**
 * The observed form of every callback prop, to be spread onto `<ReactFlow />`
 * **after** the fixture's own props — each records its call and then defers to
 * whatever `props` held under the same name.
 *
 * Empty unless the URL asked. Installing a callback prop is not free: three of
 * upstream's are presence-sensitive, and `onReconnect` alone renders a reconnect
 * anchor per edge endpoint. The net wants that — symmetric across its two sides,
 * and the only way to see a handler at all — while the conformance suite, which
 * drives this same page, must keep running upstream's fixture as upstream wrote
 * it.
 *
 * What it wrapped is reported either way, `[]` included: that empty list is how
 * a capture whose URL lost the parameter fails instead of recording an empty
 * section on both sides.
 *
 * Memoized on the handlers beneath, so a wrapper keeps its identity for as long
 * as what it wraps does. Fresh closures on every render would be honest and
 * still wrong: upstream's `StoreUpdater` copies changed handler fields into the
 * store, so a driver that reshuffled twenty-five of them per render would be
 * measuring a page nobody writes.
 */
export const useObservedHandlers = (props: Props): Props => {
  const log = publishCallLog();

  return useMemo(
    () => {
      const observed: Props = {};
      if (observationAsked()) {
        for (const name of manifest.props) {
          observed[name] = log.wrap(name, props[name] as Handler | undefined, manifest.unhandled[name]);
        }
      }
      log.observe(Object.keys(observed));
      return observed;
    },
    // A dependency per installed prop. The list is fixed at build time, so the
    // array's length is the same on every render, which is what React requires.
    manifest.props.map((name: string) => props[name])
  );
};
