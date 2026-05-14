// Minimal `ResizeObserver` wrapper. Each entry's `contentRect` is a
// `DOMRectReadOnly`; we expose the eight numeric fields directly so the
// PS side does not need a separate `DOMRect` import.

export const createResizeObserver = (callback) => () =>
  new ResizeObserver((entries) => {
    const projected = entries.map((entry) => {
      const r = entry.contentRect;
      return {
        contentRect: {
          x: r.x,
          y: r.y,
          width: r.width,
          height: r.height,
          top: r.top,
          right: r.right,
          bottom: r.bottom,
          left: r.left,
        },
        target: entry.target,
      };
    });
    callback(projected)();
  });

export const observe = (observer) => (element) => () => {
  observer.observe(element);
};

export const unobserve = (observer) => (element) => () => {
  observer.unobserve(element);
};

export const disconnect = (observer) => () => {
  observer.disconnect();
};
