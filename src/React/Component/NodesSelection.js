export const focusWithoutScrollImpl = (mEl) => () => {
  if (mEl != null) {
    mEl.focus({ preventScroll: true });
  }
};
