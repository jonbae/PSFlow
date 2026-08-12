// The two sides, and the page that serves them — named once.
//
// A side appears in three places that cannot import from each other freely:
// `build.mjs` bundles one, `index.html` imports one at runtime, and the net's
// harness navigates to one. Two of the three import this; `sides.test.mjs`
// holds `index.html` to it, since a browser page cannot.

/** `psflow` first: it is the default, and the door the audience comes through. */
export const SIDES = ["psflow", "upstream"];

/** Served by the static server from the repo root. */
export const DRIVER_PAGE = "/parity/driver/index.html";
