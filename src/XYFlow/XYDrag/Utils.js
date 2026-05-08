export const hasSelectorImpl = (target) => (selector) => (domNode) => () => {
  let current = target;
  while (current) {
    if (typeof current.matches === "function" && current.matches(selector)) {
      return true;
    }
    if (current === domNode) {
      return false;
    }
    current = current.parentElement;
  }
  return false;
};
