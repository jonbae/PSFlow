import { test } from "node:test";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { SECTIONS, TRACE_FORMAT, readTrace, validateTrace } from "./trace-format.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const fixture = (name) => join(here, "compare/fixtures", name);

const valid = () => readTrace(fixture("baseline.upstream.json"));

test("the seven sections are the trace's shape, in the documented order", () => {
  assert.deepEqual(SECTIONS, ["dom", "callbacks", "hooks", "api", "props", "console", "driving"]);
});

test("a committed fixture trace validates and keeps its envelope", () => {
  const trace = valid();
  assert.equal(trace.scenario, "mount-baseline--nodes-general");
  assert.equal(trace.side, "upstream");
  assert.equal(trace.capture, 1);
  assert.equal(trace.baseline, "12.11.0");
  assert.deepEqual(Object.keys(trace.sections).sort(), [...SECTIONS].sort());
});

test("a missing section fails rather than comparing as empty", () => {
  const trace = valid();
  delete trace.sections.console;
  assert.throws(() => validateTrace(trace, "t.json"), /console/);
});

test("a section the format does not know fails", () => {
  const trace = valid();
  trace.sections.timings = [];
  assert.throws(() => validateTrace(trace, "t.json"), /timings/);
});

test("an unknown trace format version fails", () => {
  const trace = valid();
  trace.traceFormat = TRACE_FORMAT + 1;
  assert.throws(() => validateTrace(trace, "t.json"), /traceFormat/);
});

test("a malformed dom element names its own path", () => {
  const trace = valid();
  trace.sections.dom.root.children[0].children = { "0": "not an array" };
  assert.throws(() => validateTrace(trace, "t.json"), /dom\/root\/children\/.*children/);
});

test("a driving action that stopped recording its box fails", () => {
  const trace = valid();
  delete trace.sections.driving[0].box;
  assert.throws(() => validateTrace(trace, "t.json"), /driving\/0\/box is missing/);
});

test("a driving action that stopped recording what it dispatched fails", () => {
  const trace = valid();
  delete trace.sections.driving[0].dispatched;
  assert.throws(() => validateTrace(trace, "t.json"), /driving\/0\/dispatched is missing/);
});

test("page-level state is enumerated, so dropping one of the three fails", () => {
  const trace = valid();
  delete trace.sections.dom.page.visualViewportScale;
  assert.throws(() => validateTrace(trace, "t.json"), /dom\/page\/visualViewportScale/);
});

test("every problem is reported at once rather than the first", () => {
  const trace = valid();
  delete trace.sections.console;
  delete trace.sections.props;
  assert.throws(() => validateTrace(trace, "t.json"), (e) => /console/.test(e.message) && /props/.test(e.message));
});
