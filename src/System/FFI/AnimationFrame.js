export const requestAnimationFrameImpl = (action) => () =>
  window.requestAnimationFrame(() => action());

export const cancelAnimationFrameImpl = (handle) => () => {
  window.cancelAnimationFrame(handle);
};
