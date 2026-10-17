// Nodes and edges as a JavaScript consumer writes them.
const at = { x: 0, y: 0 };

export const nodes = [
  { id: "a", position: at, data: { label: "a" } },
  { id: "b", position: at, data: { label: "b" } },
];

export const added = { id: "c", position: at, data: { label: "c" } };

export const edges = [
  { id: "a-b", source: "a", target: "b" },
  { id: "b-a", source: "b", target: "a" },
];

// A consumer's `setNodes` updater that changes `b` and hands every other
// node back as it was given.
export const relabelB = (previous) =>
  previous.map((node) => (node.id === "b" ? { ...node, data: { label: "relabelled" } } : node));
