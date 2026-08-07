// Reading record labels out of PureScript source.
//
// Shared by the two boundary gates. Both need the same thing — the field names
// of a `type X = { … }` or `type X = ( … )` declaration, live from source
// rather than from a list someone maintains — and neither can get it from the
// compiled output, because PureScript records erase to plain objects with no
// field list attached.
//
// Every failure here is a hard error. A parser that silently returned no
// fields would turn both gates green by construction, which is the failure
// this repo has had twice.

import { readFileSync } from "node:fs";

export function fail(message) {
  console.error(`boundary: ${message}`);
  process.exit(1);
}

// Strip `--` line comments, leaving anything inside a double-quoted string
// alone: `"aria-label"` is a record label here, and so are upstream's dotted
// aria-config keys.
export function stripComments(source) {
  return source
    .split("\n")
    .map((line) => {
      let inString = false;
      for (let i = 0; i < line.length; i++) {
        const c = line[i];
        if (c === '"' && line[i - 1] !== "\\") inString = !inString;
        if (!inString && c === "-" && line[i + 1] === "-") return line.slice(0, i);
      }
      return line;
    })
    .join("\n");
}

const OPEN = { "{": "}", "(": ")", "[": "]" };
const CLOSE = new Set(["}", ")", "]"]);

// The balanced text between the first delimiter after `type <Name> … =` and its
// match. Closed records are `{ … }` and open rows are `( … )`; both occur.
function declarationBody(source, typeName, where) {
  const header = new RegExp(`^type\\s+${typeName}(?:\\s+[A-Za-z0-9_' ]+)?\\s*=`, "m");
  const match = header.exec(source);
  if (!match) fail(`cannot find \`type ${typeName}\` in ${where}`);

  let i = match.index + match[0].length;
  while (i < source.length && !(source[i] in OPEN)) i++;
  if (i >= source.length) fail(`\`type ${typeName}\` in ${where} has no record or row body`);

  const start = i;
  let depth = 0;
  let inString = false;
  for (; i < source.length; i++) {
    const c = source[i];
    if (c === '"' && source[i - 1] !== "\\") inString = !inString;
    if (inString) continue;
    if (c in OPEN) depth++;
    else if (CLOSE.has(c)) {
      depth--;
      if (depth === 0) return source.slice(start + 1, i);
    }
  }
  fail(`\`type ${typeName}\` in ${where} is not balanced`);
}

// Top-level labels only: a comma inside a nested record or a type application
// does not start a new field.
function labelsOf(body, typeName, where) {
  const segments = [];
  let depth = 0;
  let inString = false;
  let current = "";
  for (let i = 0; i < body.length; i++) {
    const c = body[i];
    if (c === '"' && body[i - 1] !== "\\") inString = !inString;
    if (!inString) {
      if (c in OPEN) depth++;
      else if (CLOSE.has(c)) depth--;
      else if (c === "," && depth === 0) {
        segments.push(current);
        current = "";
        continue;
      }
    }
    current += c;
  }
  segments.push(current);

  const labels = [];
  for (const segment of segments) {
    const m = /^\s*("(?:[^"\\]|\\.)*"|[A-Za-z_][A-Za-z0-9_']*)\s*::/.exec(segment);
    if (m) labels.push(m[1].startsWith('"') ? m[1].slice(1, -1) : m[1]);
  }
  if (labels.length === 0) {
    fail(`\`type ${typeName}\` in ${where} yielded no fields — the parse is wrong`);
  }
  return labels;
}

export function readSource(path) {
  try {
    return stripComments(readFileSync(path, "utf8"));
  } catch (e) {
    fail(`cannot read ${path}: ${e.message}`);
  }
}

export function recordFields(path, typeName) {
  const source = readSource(path);
  return labelsOf(declarationBody(source, typeName, path), typeName, path);
}
