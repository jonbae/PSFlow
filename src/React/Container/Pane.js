export const eventTargetMatchesRefImpl = (event) => (ref) => () =>
  event.target === ref.current;

export const setPointerCaptureImpl = (event) => () => {
  const t = event.target;
  if (t && typeof t.setPointerCapture === "function") {
    t.setPointerCapture(event.pointerId);
  }
};

export const releasePointerCaptureImpl = (event) => () => {
  const t = event.target;
  if (t && typeof t.releasePointerCapture === "function") {
    t.releasePointerCapture(event.pointerId);
  }
};

export const stopPropagationImpl = (event) => () => {
  event.stopPropagation();
};

export const preventDefaultImpl = (event) => () => {
  event.preventDefault();
};

export const eventButtonImpl = (event) => () => event.button;

export const eventIsPrimaryImpl = (event) => () => !!event.isPrimary;
