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

// The balanced text inside the delimiter at or after `from`. Closed records are
// `{ … }` and open rows are `( … )`; both occur.
function balancedFrom(source, from, what) {
  let i = from;
  while (i < source.length && !(source[i] in OPEN)) i++;
  if (i >= source.length) fail(`${what} has no record or row body`);

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
  fail(`${what} is not balanced`);
}

function declarationBody(source, typeName, where) {
  const header = new RegExp(`^type\\s+${typeName}(?:\\s+[A-Za-z0-9_' ]+)?\\s*=`, "m");
  const match = header.exec(source);
  if (!match) fail(`cannot find \`type ${typeName}\` in ${where}`);
  return balancedFrom(source, match.index + match[0].length, `\`type ${typeName}\` in ${where}`);
}

// The text of a `data <Name> … = … | …` declaration: everything from its header
// up to the next declaration starting in column 1.
function dataBody(source, typeName, where) {
  const header = new RegExp(`^data\\s+${typeName}\\b`, "m").exec(source);
  if (!header) fail(`cannot find \`data ${typeName}\` in ${where}`);
  const rest = source.slice(header.index);
  const end = /\n(?=\S)/.exec(rest.slice(1));
  return end ? rest.slice(0, end.index + 1) : rest;
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

// The constructor names of a sum type, in declaration order. Used to catch a
// member added to `NodeChange` or `EdgeChange` that the crossing never learned
// about — the union's equivalent of a record gaining a field.
export function dataConstructors(path, typeName) {
  const body = dataBody(readSource(path), typeName, path);
  const names = [...body.matchAll(/[=|]\s*([A-Z][A-Za-z0-9_']*)/g)].map((m) => m[1]);
  if (names.length === 0) {
    fail(`\`data ${typeName}\` in ${path} yielded no constructors — the parse is wrong`);
  }
  return names;
}

// The labels of the record a single constructor carries.
export function constructorFields(path, typeName, ctorName) {
  const source = readSource(path);
  const body = dataBody(source, typeName, path);
  const ctor = new RegExp(`\\b${ctorName}\\b`).exec(body);
  if (!ctor) fail(`\`data ${typeName}\` in ${path} has no constructor ${ctorName}`);
  const where = `${typeName}.${ctorName} in ${path}`;
  return labelsOf(balancedFrom(body, ctor.index + ctorName.length, where), where, path);
}
