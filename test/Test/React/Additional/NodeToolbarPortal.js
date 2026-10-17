// `spago test` has no DOM, and the server renderer can't render a portal, so
// the portal's target is read off a stand-in root: an element whose
// `querySelector` answers only for the renderer.
export const renderer = { stand_in: "react-flow__renderer" };

export const fakeRoot = {
  querySelector: (selector) => (selector === ".react-flow__renderer" ? renderer : null),
};

export const sameRef = (a) => (b) => a === b;
