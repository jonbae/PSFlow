// Paths and path patterns — the address of a single difference inside a trace,
// and the language normalization rules and regions use to point at one.
//
// A path is an array of raw segments (`["dom", "root", "attrs", "class"]`).
// It renders with `/` separators, escaping `/` as `~1` and `~` as `~0` so a
// segment carrying a slash — an api query key, say — stays one segment.
//
// A pattern is a `/`-joined string of segment patterns, where `*` matches
// exactly one segment and `**` matches any number, including none.

export const formatPath = (path) =>
  path.map((s) => String(s).replace(/~/g, "~0").replace(/\//g, "~1")).join("/");

export const parsePattern = (pattern) => pattern.split("/");

const matchSegments = (pattern, path, pi, si) => {
  if (pi === pattern.length) return si === path.length;
  if (pattern[pi] === "**") {
    for (let skip = si; skip <= path.length; skip++) {
      if (matchSegments(pattern, path, pi + 1, skip)) return true;
    }
    return false;
  }
  if (si === path.length) return false;
  if (pattern[pi] !== "*" && pattern[pi] !== String(path[si])) return false;
  return matchSegments(pattern, path, pi + 1, si + 1);
};

/** `pattern` may be the string form or the pre-parsed segment array. */
export const matchPath = (pattern, path) =>
  matchSegments(Array.isArray(pattern) ? pattern : parsePattern(pattern), path, 0, 0);

const MISSING = Symbol("missing");
export { MISSING };

export const getAt = (value, path) => {
  let here = value;
  for (const segment of path) {
    if (here === null || typeof here !== "object") return MISSING;
    const key = Array.isArray(here) ? Number(segment) : segment;
    if (!(key in here)) return MISSING;
    here = here[key];
  }
  return here;
};
