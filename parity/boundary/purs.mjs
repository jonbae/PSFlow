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

// One left-to-right walk, and the only one. Every reader below wants the same
// two things — how deep it is, and whether it is inside a string literal — and
// getting that subtly wrong in four places is how a reader starts agreeing
// with anything. `visit` sees each character with the nesting depth *outside*
// it, so a top-level comma, `|` or closing delimiter all report depth 0;
// returning `true` stops the walk.
function walk(text, visit) {
  let depth = 0;
  let inString = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '"' && text[i - 1] !== "\\") inString = !inString;
    if (inString) continue;
    if (CLOSE.has(c)) depth--;
    if (visit(c, depth, i)) return;
    if (c in OPEN) depth++;
  }
}

// The index of the delimiter closing the one that opens at `from`, or -1.
function closerFor(text, from) {
  let end = -1;
  walk(text.slice(from), (c, depth, i) => {
    if (CLOSE.has(c) && depth === 0) {
      end = from + i;
      return true;
    }
    return false;
  });
  return end;
}

// The balanced text inside the delimiter at or after `from`. Closed records are
// `{ … }` and open rows are `( … )`; both occur.
function balancedFrom(source, from, what) {
  let start = from;
  while (start < source.length && !(source[start] in OPEN)) start++;
  if (start >= source.length) fail(`${what} has no record or row body`);
  const end = closerFor(source, start);
  if (end < 0) fail(`${what} is not balanced`);
  return source.slice(start + 1, end);
}

function declarationBody(source, typeName, where) {
  const header = new RegExp(`^type\\s+${typeName}(?:\\s+[A-Za-z0-9_' ]+)?\\s*=`, "m");
  const match = header.exec(source);
  if (!match) fail(`cannot find \`type ${typeName}\` in ${where}`);
  return balancedFrom(source, match.index + match[0].length, `\`type ${typeName}\` in ${where}`);
}


// ── Row composition ───────────────────────────────────────────────────────
//
// A record can state an intersection once instead of transcribing both halves.
// `ReactFlowInstance` is `Record (GeneralHelpersRow n e (…))`, which is how
// upstream's `GeneralHelpers & ViewportHelperFunctions & { … }` is spelled in
// PureScript, and the three path-shaped edge props records are one row plus a
// `pathOptions`. Both gates want their labels all the same, so the composition
// is expanded here rather than the source being asked to repeat itself: a
// record duplicated to suit an instrument is two records that can drift apart,
// which is the class of failure these gates exist to catch.
//
// Labels are all either gate reads, so nothing is substituted into a field's
// *type* — only the row a synonym extends is followed.
//
// The limit, and it is a real one: a synonym has to be declared in the same
// module as the record composed from it. Both of today's compositions are, and
// a row imported from elsewhere fails by name rather than reading short — but
// the day one crosses a module boundary, this is what has to grow.

// `type <Name> <params…> = …` — its parameter names and its right-hand side,
// which runs to the next declaration starting in column 1. Null when the
// module declares no such type.
function synonymDeclaration(source, name) {
  const header = new RegExp(`^type\\s+${name}((?:\\s+[A-Za-z][A-Za-z0-9_']*)*)\\s*=`, "m");
  const match = header.exec(source);
  if (!match) return null;
  const rest = source.slice(match.index + match[0].length);
  const stop = /\n(?=\S)/.exec(rest);
  return {
    params: match[1].trim().split(/\s+/).filter(Boolean),
    rhs: stop ? rest.slice(0, stop.index) : rest,
  };
}

// Splits a row body at its top-level `|` — `( a :: T | rest )` — into the
// fields it declares itself and the row it extends.
function splitRowTail(body) {
  let bar = -1;
  walk(body, (c, depth, i) => {
    if (c === "|" && depth === 0) {
      bar = i;
      return true;
    }
    return false;
  });
  if (bar < 0) return { fields: body, tail: null };
  return { fields: body.slice(0, bar), tail: body.slice(bar + 1).trim() };
}

// `Name arg1 arg2 …` split into the head and its arguments, **parentheses
// kept**: an argument is either a bare token or a balanced parenthesised
// group, and keeping the parens is what tells a row literal from a name. A
// qualified head (`Other.Row`) is captured whole, so the failure that follows
// names what it could not find rather than its module alias.
function applicationOf(text) {
  const match = /^([A-Z][A-Za-z0-9_']*(?:\.[A-Z][A-Za-z0-9_']*)*)([\s\S]*)$/.exec(text.trim());
  if (!match) return null;
  const rest = match[2];
  const args = [];
  let i = 0;
  while (i < rest.length) {
    if (/\s/.test(rest[i])) {
      i++;
      continue;
    }
    if (rest[i] === "(") {
      const end = closerFor(rest, i);
      if (end < 0) return null;
      args.push(rest.slice(i, end + 1));
      i = end + 1;
    } else {
      let j = i;
      while (j < rest.length && !/[\s()]/.test(rest[j])) j++;
      args.push(rest.slice(i, j));
      i = j;
    }
  }
  return { name: match[1], args };
}

// A synonym's parameters bound to the argument texts, and the scope those
// texts were written in. A chain rather than a substitution into the source:
// an argument means whatever it meant where it was written, not where the
// parameter is used.
const bind = (params, args, outer) => ({
  bindings: Object.fromEntries(params.map((name, i) => [name, args[i] ?? ""])),
  outer,
});

// A cap, not a budget: expansion recurses a step per parenthesis and per bound
// parameter as well as per synonym, so a real composition reaches several
// times its own nesting. What it catches is a cycle — which `purs` rejects, so
// it can only arise in source that does not compile. That is source this
// reader is handed anyway: the drift check reads `.purs` files directly and
// needs no build, and a named failure beats a stack overflow.
const MAX_ROW_DEPTH = 64;

// The entries of a row expression: a literal `{ … }` / `( … )`, a `Record …`
// application, a synonym applied to its arguments, or a bound parameter.
function rowEntries(source, text, scope, typeName, where, depth = 0) {
  const expression = text.trim();
  if (expression === "") return [];
  if (depth > MAX_ROW_DEPTH) {
    fail(
      `\`type ${typeName}\` in ${where}: expansion went ${MAX_ROW_DEPTH} steps deep — ` +
        `the row synonyms it is composed from are almost certainly cyclic`
    );
  }
  const into = (next, nextScope) => rowEntries(source, next, nextScope, typeName, where, depth + 1);

  if (expression[0] === "{" || expression[0] === "(") {
    const inner = balancedFrom(expression, 0, `\`type ${typeName}\` in ${where}`);
    const { fields, tail } = splitRowTail(inner);
    const entries = segmentEntries(fields);
    // No labels and no tail means the parentheses grouped an expression rather
    // than opening a row literal — `(SomeRow n ())`.
    if (entries.length === 0 && tail === null) return into(inner, scope);
    return tail === null ? entries : [...entries, ...into(tail, scope)];
  }

  // A type parameter, and only this synonym's own — walking out to an enclosing
  // scope would let a body reference a parameter it never declared, which is
  // capture rather than lookup. Bound, it is whatever was passed for it, read
  // in the scope that passed it; unbound, it is a row this expansion was never
  // given, and contributes no labels.
  if (/^[a-z][A-Za-z0-9_']*$/.test(expression)) {
    if (scope && expression in scope.bindings) {
      return into(scope.bindings[expression], scope.outer);
    }
    return [];
  }

  const application = applicationOf(expression);
  if (!application) {
    fail(`\`type ${typeName}\` in ${where}: cannot read \`${expression}\` as a record or row`);
  }
  if (application.name === "Record") return into(application.args[0] ?? "", scope);

  const declaration = synonymDeclaration(source, application.name);
  if (!declaration) {
    fail(
      `\`type ${typeName}\` in ${where} is composed from \`${application.name}\`, which is ` +
        `not declared in the same module — the expansion cannot see it`
    );
  }
  return into(declaration.rhs, bind(declaration.params, application.args, scope));
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
function segmentsOf(body) {
  const cuts = [];
  walk(body, (c, depth, i) => {
    if (c === "," && depth === 0) cuts.push(i);
    return false;
  });
  const segments = [];
  let from = 0;
  for (const cut of [...cuts, body.length]) {
    segments.push(body.slice(from, cut));
    from = cut + 1;
  }
  return segments;
}

// One entry per field: its label, and the source text of its type. The type
// text is what lets a caller tell a callback prop from a data one without a
// list of its own.
function segmentEntries(body) {
  const entries = [];
  for (const segment of segmentsOf(body)) {
    const m = /^\s*("(?:[^"\\]|\\.)*"|[A-Za-z_][A-Za-z0-9_']*)\s*::([\s\S]*)$/.exec(segment);
    if (m) {
      entries.push({
        name: m[1].startsWith('"') ? m[1].slice(1, -1) : m[1],
        type: m[2].trim().replace(/\s+/g, " "),
      });
    }
  }
  return entries;
}

function entriesOf(body, typeName, where) {
  const entries = segmentEntries(body);
  if (entries.length === 0) {
    fail(`\`type ${typeName}\` in ${where} yielded no fields — the parse is wrong`);
  }
  return entries;
}

function labelsOf(body, typeName, where) {
  return entriesOf(body, typeName, where).map((entry) => entry.name);
}

export function readSource(path) {
  try {
    return stripComments(readFileSync(path, "utf8"));
  } catch (e) {
    fail(`cannot read ${path}: ${e.message}`);
  }
}

export function recordFields(path, typeName) {
  return recordEntries(path, typeName).map((entry) => entry.name);
}

// The same declaration, with each field's type text alongside its label. One
// written as a single literal — all but a handful of them — is read straight
// off; one composed out of row synonyms is expanded first.
export function recordEntries(path, typeName) {
  const source = readSource(path);
  const declaration = synonymDeclaration(source, typeName);
  if (!declaration) fail(`cannot find \`type ${typeName}\` in ${path}`);
  const entries = rowEntries(source, declaration.rhs, null, typeName, path);
  if (entries.length === 0) {
    fail(`\`type ${typeName}\` in ${path} yielded no fields — the parse is wrong`);
  }
  const seen = new Set();
  for (const entry of entries) {
    if (seen.has(entry.name)) {
      fail(
        `\`type ${typeName}\` in ${path} declares \`${entry.name}\` twice once expanded — ` +
          `two of the rows composed into it carry the same label`
      );
    }
    seen.add(entry.name);
  }
  return entries;
}

// The names a module declares as `type X = …`, in declaration order. Used to
// find out which types are handler types without restating the list.
export function typeSynonyms(path) {
  const names = [...readSource(path).matchAll(/^type\s+([A-Z][A-Za-z0-9_']*)/gm)].map(
    (m) => m[1]
  );
  if (names.length === 0) {
    fail(`${path} declares no type synonyms — the parse is wrong`);
  }
  return names;
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
