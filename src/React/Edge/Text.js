// JavaScript truthiness, which is the test upstream's `if (!label)` and
// BaseEdge's `label && …` apply: an empty string, and the `0` a JavaScript
// consumer's `ReactNode` label can be, draw no label at all.
export const labelShown = (label) => !!label;

export const measureText = (element) => () => {
  const bbox = element.getBBox();

  return {
    x: bbox.x,
    y: bbox.y,
    width: bbox.width,
    height: bbox.height,
  };
};
