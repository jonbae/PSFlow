// The in-page observation bridge for the net's `hooks`, `api` and `props`
// sections (#59).
//
// Probe components write into it while they render; the harness reads one
// serialized end-state snapshot after the page settles. The imperative
// instance is attached separately so queries are evaluated at read time, after
// the scenario has finished driving, while mutators go through `call` and land
// in the driving log.

import { serializeValue } from "../system/harness/serialize.mjs";

/** The one page global shared by the driver and the harness port. */
export const OBSERVATIONS = "__psflowNet";

const QUERY_READERS = Object.freeze({
  getNodes: (instance) => instance.getNodes(),
  getEdges: (instance) => instance.getEdges(),
  toObject: (instance) => instance.toObject(),
  getZoom: (instance) => instance.getZoom(),
  getViewport: (instance) => instance.getViewport(),
  viewportInitialized: (instance) => instance.viewportInitialized,
});

const errorValue = (error) => ({ error: String(error?.message ?? error) });

export class ObservationError extends Error {
  constructor(message) {
    super(message);
    this.name = "ObservationError";
  }
}

export const createObservationLog = ({ maxDepth } = {}) => {
  const hooks = {};
  const props = {};
  const extraQueries = {};
  const failures = [];
  let instance = null;

  const serialize = (value, path) => serializeValue(value, { path, maxDepth });

  const record = (section, probe, value, path) => {
    try {
      section[probe] = serialize(value, path);
    } catch (error) {
      failures.push({ path: path.join("/"), error: String(error?.message ?? error) });
    }
  };

  const snapshotQueries = () => {
    const queries = { ...extraQueries };
    if (!instance) return queries;

    for (const [name, read] of Object.entries(QUERY_READERS)) {
      try {
        queries[name] = serialize(read(instance), ["api", "queries", name]);
      } catch (error) {
        // A query that throws is still an observed answer. Keeping it in the
        // section makes the difference comparable instead of turning capture
        // into an infrastructure failure.
        queries[name] = errorValue(error);
      }
    }
    return queries;
  };

  return {
    attach(next) {
      instance = next;
    },

    recordHook(probe, name, value) {
      hooks[probe] ??= {};
      record(hooks[probe], name, value, ["hooks", probe, name]);
    },

    recordHookError(probe, name, error) {
      hooks[probe] ??= {};
      hooks[probe][name] = errorValue(error);
    },

    recordProps(probe, value) {
      record(props, probe, value, ["props", probe]);
    },

    recordQuery(name, value) {
      record(extraQueries, name, value, ["api", "queries", name]);
    },

    async call(method, args) {
      if (!instance) throw new ObservationError("no ReactFlow instance is attached");
      const member = instance[method];
      if (typeof member !== "function") {
        throw new ObservationError(`ReactFlowInstance has no method ${JSON.stringify(method)}`);
      }
      try {
        return serialize(await member(...args), ["api", "calls", method, "result"]);
      } catch (error) {
        return errorValue(error);
      }
    },

    read() {
      return {
        hooks: structuredClone(hooks),
        api: { queries: snapshotQueries() },
        props: structuredClone(props),
        failures: failures.slice(),
      };
    },
  };
};

/** Installs once because the entry point and every probe need the same log. */
export const installObservationLog = (target, options) => {
  if (!target[OBSERVATIONS]) target[OBSERVATIONS] = createObservationLog(options);
  return target[OBSERVATIONS];
};
