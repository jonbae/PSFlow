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
  getNode: (instance) => instance.getNode(instance.getNodes()[0]?.id ?? "__psflow_missing_node"),
  getInternalNode: (instance) =>
    instance.getInternalNode(instance.getNodes()[0]?.id ?? "__psflow_missing_node"),
  getEdges: (instance) => instance.getEdges(),
  getEdge: (instance) => instance.getEdge(instance.getEdges()[0]?.id ?? "__psflow_missing_edge"),
  getIntersectingNodes: (instance) =>
    instance.getIntersectingNodes({ x: 0, y: 0, width: 0, height: 0 }),
  isNodeIntersecting: (instance) =>
    instance.isNodeIntersecting(
      { id: instance.getNodes()[0]?.id ?? "__psflow_missing_node" },
      { x: 0, y: 0, width: 0, height: 0 },
      true
    ),
  getNodesBounds: (instance) => instance.getNodesBounds(instance.getNodes().map(({ id }) => id)),
  getHandleConnections: (instance) =>
    instance.getHandleConnections({
      type: "source",
      nodeId: instance.getNodes()[0]?.id ?? "__psflow_missing_node",
    }),
  getNodeConnections: (instance) =>
    instance.getNodeConnections({ nodeId: instance.getNodes()[0]?.id ?? "__psflow_missing_node" }),
  toObject: (instance) => instance.toObject(),
  getZoom: (instance) => instance.getZoom(),
  getViewport: (instance) => instance.getViewport(),
  screenToFlowPosition: (instance) => instance.screenToFlowPosition({ x: 0, y: 0 }),
  flowToScreenPosition: (instance) => instance.flowToScreenPosition({ x: 0, y: 0 }),
  viewportInitialized: (instance) => instance.viewportInitialized,
});

export const IMPERATIVE_QUERIES = Object.freeze(Object.keys(QUERY_READERS));

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
  const queryReaders = new Map();
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
    const queries = {};
    for (const [name, read] of queryReaders) {
      try {
        queries[name] = serialize(read(), ["api", "queries", name]);
      } catch (error) {
        queries[name] = errorValue(error);
      }
    }
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

    registerQuery(name, read) {
      if (typeof read !== "function") throw new ObservationError(`${name}: a query reader must be a function`);
      queryReaders.set(name, read);
      return () => {
        if (queryReaders.get(name) === read) queryReaders.delete(name);
      };
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
