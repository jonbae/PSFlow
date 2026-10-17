// Nodes as a JavaScript consumer writes them, so `style` holds the numbers
// and strings the consumer passed rather than what ps-flow's `Object String`
// claims.
const at = { x: 0, y: 0 };

export const styledNode = { id: "a", position: at, data: {}, style: { width: 320, height: 220 } };

export const cssStyledNode = { id: "a", position: at, data: {}, style: { width: "100%", height: "4rem" } };

export const sizedStyledNode = { id: "a", position: at, data: {}, width: 50, height: 30, style: { width: 320, height: 220 } };

export const initialSizedStyledNode = {
  id: "a",
  position: at,
  data: {},
  initialWidth: 10,
  initialHeight: 12,
  style: { width: 320, height: 220 },
};

export const plainNode = { id: "a", position: at, data: {} };

export const is = (expected) => (actual) => Object.is(actual, expected);
export const nullForeign = null;
