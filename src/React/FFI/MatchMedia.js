// `window.matchMedia('(prefers-color-scheme: dark)')` subscription
// wrapper. Returns `current` (the current boolean) and `subscribe`
// (install a `change` listener, return a cleanup).

export const prefersDarkMode = () => {
  const mql = window.matchMedia("(prefers-color-scheme: dark)");
  return {
    current: () => mql.matches,
    subscribe: (handler) => () => {
      const listener = (event) => handler(event.matches)();
      // `addEventListener` is the modern API; older Safari fell back
      // to `addListener`. We support both via feature detection.
      if (mql.addEventListener) {
        mql.addEventListener("change", listener);
        return () => mql.removeEventListener("change", listener);
      } else {
        mql.addListener(listener);
        return () => mql.removeListener(listener);
      }
    },
  };
};
