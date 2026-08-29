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

export const TRACE_FORMAT = 2;

// The receipt for the input side, named because three modules downstream ask
// whether a difference landed in it.
export const DRIVING = "driving";

// Named for the same reason one section further on: `callbacks` is the one
// section with a comparison of its own (#44), so both comparison paths have to
// ask whether they are looking at it.
export const CALLBACKS = "callbacks";

// Order is the format's own; the *report* leads with `driving` instead, because
// inputs that differed make output differences uninterpretable (#26).
export const SECTIONS = ["dom", CALLBACKS, "hooks", "api", "props", "console", DRIVING];

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

// Page-level state is enumerated rather than open: two upstream behaviours turn
// on a browser default *not* happening, and a capture that quietly stopped
// recording one of them would compare clean on both sides.
const PAGE_STATE = ["scrollX", "scrollY", "visualViewportScale"];

const SECTION_CHECKS = {
  dom: (dom, path, problems) => {
    if (!isPlainObject(dom)) return void problems.push(`${path} must be an object`);
    if (!isPlainObject(dom.page)) problems.push(`${path}/page must be an object`);
    else {
      for (const field of PAGE_STATE) {
        if (typeof dom.page[field] !== "number") problems.push(`${path}/page/${field} must be a number`);
      }
    }
    if (dom.root !== null) checkElement(dom.root, `${path}/root`, problems);
  },
  callbacks: (callbacks, path, problems) => {
    if (!Array.isArray(callbacks)) return void problems.push(`${path} must be an array`);
    callbacks.forEach((entry, i) => {
      if (!isPlainObject(entry)) return void problems.push(`${path}/${i} must be an object`);
      if (typeof entry.name !== "string") problems.push(`${path}/${i}/name must be a string`);
      if (!Array.isArray(entry.args)) problems.push(`${path}/${i}/args must be an array`);
      if ("probe" in entry && typeof entry.probe !== "boolean") problems.push(`${path}/${i}/probe must be boolean`);
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
  // The driving log is the receipt for the input side, and every field of it is
  // load-bearing: the box is the sub-pixel measurement the whole self-consistency
  // check turns on, and `resolved: false` is how a missing element reads as a
  // finding instead of as a Playwright timeout. A capture that stopped writing
  // one of them would compare clean on both sides, so all five are required —
  // `target`, `box` and `dispatched` nullable, because an imperative call has no
  // target and an unresolved one has no box.
  driving: (actions, path, problems) => {
    if (!Array.isArray(actions)) return void problems.push(`${path} must be an array`);
    actions.forEach((action, i) => {
      if (!isPlainObject(action)) return void problems.push(`${path}/${i} must be an object`);
      if (!Number.isInteger(action.index)) problems.push(`${path}/${i}/index must be an integer`);
      if (typeof action.action !== "string") problems.push(`${path}/${i}/action must be a string`);
      if (typeof action.resolved !== "boolean") problems.push(`${path}/${i}/resolved must be a boolean`);
      if (action.target !== null && typeof action.target !== "string") {
        problems.push(`${path}/${i}/target must be a selector or null`);
      }
      if (action.box !== null && !isPlainObject(action.box)) problems.push(`${path}/${i}/box must be an object or null`);
      if (action.resolved && action.box === undefined) problems.push(`${path}/${i}/box is missing`);
      if (!("dispatched" in action)) problems.push(`${path}/${i}/dispatched is missing`);
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
