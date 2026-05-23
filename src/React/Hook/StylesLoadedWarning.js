export const checkPaneZIndex = () => {
  if (typeof document === "undefined" || typeof window === "undefined") {
    return null;
  }
  const pane = document.querySelector(".react-flow__pane");
  if (!pane) return null;
  return window.getComputedStyle(pane).zIndex;
};
