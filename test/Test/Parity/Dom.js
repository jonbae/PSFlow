// Stand-ins for the DOM objects `isInputDOMNode` and `hasSelector` read, in
// the members a browser gives each kind of node. Only an element has
// `hasAttribute`, `closest` and `matches`; a text node has a `parentElement`
// and nothing else they read; a document has a `nodeType` and no parent; a
// window has neither.

const classSelector = (selector) => (selector.startsWith(".") ? selector.slice(1) : null);

const element = (nodeName, { classes = [], attributes = [], parent = null } = {}) => {
  const el = {
    label: `${nodeName.toLowerCase()}${classes.map((c) => `.${c}`).join("")}${attributes.map((a) => `[${a}]`).join("")}`,
    nodeType: 1,
    nodeName,
    parentElement: parent,
    hasAttribute: (name) => attributes.includes(name),
    matches: (selector) => classes.includes(classSelector(selector)),
    closest: (selector) => {
      for (let current = el; current; current = current.parentElement) {
        if (current.matches(selector)) return current;
      }
      return null;
    },
  };
  return el;
};

const textNode = (parent) => ({ label: `text in ${parent.label}`, nodeType: 3, nodeName: "#text", parentElement: parent });
const documentNode = { label: "document", nodeType: 9, nodeName: "#document", parentElement: null };
const windowObject = { label: "window" };

// The flow's node, its `.nokey` and `.nodrag` regions, and what sits in them.
const flowNode = element("DIV", { classes: ["react-flow__node"] });
const nokey = element("DIV", { classes: ["nokey"], parent: flowNode });
const nodrag = element("DIV", { classes: ["nodrag"], parent: flowNode });
const outside = element("DIV", { classes: ["outside"] });

const targets = [
  element("INPUT", { parent: flowNode }),
  element("SELECT", { parent: flowNode }),
  element("TEXTAREA", { parent: flowNode }),
  element("BUTTON", { parent: flowNode }),
  element("A", { parent: flowNode }),
  element("DIV", { parent: flowNode }),
  element("DIV", { attributes: ["contenteditable"], parent: flowNode }),
  nokey,
  element("SPAN", { parent: nokey }),
  nodrag,
  element("SPAN", { parent: nodrag }),
  textNode(nodrag),
  textNode(nokey),
  textNode(flowNode),
  flowNode,
  outside,
  documentNode,
  windowObject,
  null,
];

const labelOf = (target) => (target === null ? "null" : target.label);

// Each target three ways: as `event.target` with no `composedPath`, as
// `event.target` with an empty `composedPath`, and as the first entry of a
// `composedPath` whose `target` is the flow's node, as a shadow root reports it.
export const keyEvents = targets.flatMap((target) => [
  { label: `target ${labelOf(target)}`, target },
  { label: `target ${labelOf(target)}, empty composedPath`, target, composedPath: () => [] },
  { label: `composedPath ${labelOf(target)}`, target: flowNode, composedPath: () => [target] },
]);

export const dragTargets = targets;
export const dragNode = flowNode;
export const standInLabel = labelOf;
export const eventLabel = (event) => event.label;

// Runs a PSFlow predicate, reporting a throw as `"throws"`, as the oracle
// reports upstream's.
export const answer = (run) => {
  try {
    return run() ? "true" : "false";
  } catch (_e) {
    return "throws";
  }
};

// The event with its `composedPath` dropped, for the falsification probe.
export const withoutComposedPath = (event) => ({ label: event.label, target: event.target });
