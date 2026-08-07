// The trace format — the seam between the net's capture step and its compare
// step (issue #40, spec #37 §A).
//
// A trace is everything one run of one side recorded, written to disk as JSON.
// Its shape was decided across four closed tickets (#18 observation, #19 noise
// policy, #21 test debt, #26 corpus) and is written out in one place here and in
// `parity/system/README.md` so nobody has to reconstruct it from closed issues.
//
// Validation is deliberately strict and hard-failing. A trace missing a section
// would otherwise compare as "no differences in that section" — the
// print-instead-of-fail mistake this repo has already paid for twice.

import { readFileSync } from "node:fs";

export const TRACE_FORMAT = 1;

// Order is the format's own; the *report* leads with `driving` instead, because
// inputs that differed make output differences uninterpretable (#26).
export const SECTIONS = ["dom", "callbacks", "hooks", "api", "props", "console", "driving"];

export class TraceFormatError extends Error {
  constructor(label, problems) {
    super(`${label} is not a valid trace:\n` + problems.map((p) => "  - " + p).join("\n"));
    this.name = "TraceFormatError";
    this.problems = problems;
  }
}

const isPlainObject = (v) => typeof v === "object" && v !== null && !Array.isArray(v);

// ── Section shapes ─────────────────────────────────────────────────────────
// Each checker pushes every problem it finds; nothing stops at the first.

const checkElement = (el, path, problems) => {
  if (!isPlainObject(el)) {
    problems.push(`${path} must be an element object`);
    return;
  }
  if (typeof el.tag !== "string" || el.tag === "") problems.push(`${path}/tag must be a non-empty string`);
  if (!isPlainObject(el.attrs)) problems.push(`${path}/attrs must be an object`);
  else {
    for (const [name, value] of Object.entries(el.attrs)) {
      if (typeof value !== "string") problems.push(`${path}/attrs/${name} must be a string`);
    }
  }
  if ("text" in el && typeof el.text !== "string") problems.push(`${path}/text must be a string when present`);
  if (!Array.isArray(el.children)) {
    problems.push(`${path}/children must be an array`);
    return;
  }
  el.children.forEach((child, i) => checkElement(child, `${path}/children/${i}`, problems));
};

const SECTION_CHECKS = {
  dom: (dom, path, problems) => {
    if (!isPlainObject(dom)) return void problems.push(`${path} must be an object`);
    if (!isPlainObject(dom.page)) problems.push(`${path}/page must be an object`);
    if (dom.root !== null) checkElement(dom.root, `${path}/root`, problems);
  },
  callbacks: (callbacks, path, problems) => {
    if (!Array.isArray(callbacks)) return void problems.push(`${path} must be an array`);
    callbacks.forEach((entry, i) => {
      if (!isPlainObject(entry)) return void problems.push(`${path}/${i} must be an object`);
      if (typeof entry.name !== "string") problems.push(`${path}/${i}/name must be a string`);
      if (!Array.isArray(entry.args)) problems.push(`${path}/${i}/args must be an array`);
    });
  },
  hooks: (hooks, path, problems) => {
    if (!isPlainObject(hooks)) return void problems.push(`${path} must be an object keyed by probe id`);
  },
  api: (api, path, problems) => {
    if (!isPlainObject(api)) return void problems.push(`${path} must be an object`);
    if (!isPlainObject(api.queries)) problems.push(`${path}/queries must be an object`);
    if (!Array.isArray(api.calls)) problems.push(`${path}/calls must be an array`);
  },
  props: (props, path, problems) => {
    if (!isPlainObject(props)) return void problems.push(`${path} must be an object keyed by probe id`);
  },
  console: (entries, path, problems) => {
    if (!Array.isArray(entries)) return void problems.push(`${path} must be an array`);
    entries.forEach((entry, i) => {
      if (!isPlainObject(entry)) return void problems.push(`${path}/${i} must be an object`);
      if (typeof entry.level !== "string") problems.push(`${path}/${i}/level must be a string`);
      if (typeof entry.text !== "string") problems.push(`${path}/${i}/text must be a string`);
    });
  },
  driving: (actions, path, problems) => {
    if (!Array.isArray(actions)) return void problems.push(`${path} must be an array`);
    actions.forEach((action, i) => {
      if (!isPlainObject(action)) return void problems.push(`${path}/${i} must be an object`);
      if (typeof action.action !== "string") problems.push(`${path}/${i}/action must be a string`);
      if (typeof action.resolved !== "boolean") problems.push(`${path}/${i}/resolved must be a boolean`);
    });
  },
};

/**
 * Throws a TraceFormatError listing every problem found. `label` is whatever
 * identifies the trace to a human — a file path, usually.
 */
export const validateTrace = (trace, label) => {
  const problems = [];

  if (!isPlainObject(trace)) throw new TraceFormatError(label, ["not a JSON object"]);

  if (trace.traceFormat !== TRACE_FORMAT) {
    problems.push(`traceFormat must be ${TRACE_FORMAT}, got ${JSON.stringify(trace.traceFormat)}`);
  }
  for (const field of ["scenario", "side", "baseline"]) {
    if (typeof trace[field] !== "string" || trace[field] === "") problems.push(`${field} must be a non-empty string`);
  }
  if (!Number.isInteger(trace.capture) || trace.capture < 1) problems.push("capture must be a positive integer");

  if (!isPlainObject(trace.sections)) {
    problems.push("sections must be an object carrying all seven sections");
    throw new TraceFormatError(label, problems);
  }

  for (const section of SECTIONS) {
    if (!(section in trace.sections)) {
      // Capture records everything: an absent section is a broken capture, not
      // a section that happened to be empty.
      problems.push(`sections/${section} is missing`);
      continue;
    }
    SECTION_CHECKS[section](trace.sections[section], `${section}`, problems);
  }
  for (const name of Object.keys(trace.sections)) {
    if (!SECTIONS.includes(name)) problems.push(`sections/${name} is not one of the seven sections`);
  }

  if (problems.length) throw new TraceFormatError(label, problems);
  return trace;
};

export const readTrace = (path) => {
  let parsed;
  try {
    parsed = JSON.parse(readFileSync(path, "utf8"));
  } catch (e) {
    throw new TraceFormatError(path, [`could not be read as JSON: ${e.message}`]);
  }
  return validateTrace(parsed, path);
};
