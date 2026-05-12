export const classListContains = (element) => (cls) => () => {
  if (!element || !element.classList) return false;
  return element.classList.contains(cls);
};
