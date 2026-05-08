export const isMultiTouchSourceEvent = (event) => () => {
  if (event && event.type === "touchmove" && event.touches) {
    return event.touches.length > 1;
  }
  return false;
};

export const mouseButtonIsZero = (event) => () => !event.button;

export const mouseEventTarget = (event) => () => event.target;

// Math.round rounds half-away-from-zero in TS; PS's Data.Int.round rounds
// banker-style. Mirror the TS by hand.
export const roundHalfAway = (n) => {
  if (n >= 0) return Math.floor(n + 0.5);
  return -Math.floor(-n + 0.5);
};
