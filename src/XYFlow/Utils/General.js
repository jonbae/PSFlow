"use strict";

export const isMacOsImpl = () =>
  typeof navigator !== "undefined" &&
  typeof navigator.userAgent === "string" &&
  navigator.userAgent.indexOf("Mac") >= 0;
