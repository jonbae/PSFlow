"use strict";

export const eventType = (event) => () => (event && event.type) || "";
export const eventButton = (event) => () =>
  event && typeof event.button === "number" ? event.button : 0;
export const eventCtrlKey = (event) => () => !!(event && event.ctrlKey);
export const eventTouchesLength = (event) => () => {
  if (event && event.touches && typeof event.touches.length === "number") {
    return event.touches.length;
  }
  return 0;
};
export const eventPreventDefault = (event) => () => {
  if (event && typeof event.preventDefault === "function") {
    event.preventDefault();
  }
};
