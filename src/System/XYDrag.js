export const isMultiTouchSourceEvent = (event) => () => {
  if (event && event.type === "touchmove" && event.touches) {
    return event.touches.length > 1;
  }
  return false;
};

export const mouseButtonIsZero = (event) => () => !event.button;

export const mouseEventTarget = (event) => () => event.target;
