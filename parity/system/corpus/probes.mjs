// Selective probe variants (#59).
//
// The durable plan is generated from coverage holes and their witnesses: the
// witness supplies the runtime hook/method/probe name, so nobody chooses a
// component by reading the public surface again. A plan then asks for the
// smallest set of existing scenarios whose declared capability can make those
// observations live. Each variant keeps the source scenario's route and run;
// the driver derives its probe graph from the fixture at runtime.

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { defineScenario } from "../harness/scenario.mjs";
import { coverageOutcomes, exportEntries } from "../coverage/coverage.mjs";

const here = dirname(fileURLToPath(import.meta.url));
export const PROBE_PLAN = join(here, "probe-plan.json");
const CLASSIFICATION = join(here, "..", "..", "census", "classification.json");
const WITNESSES = join(here, "..", "coverage", "witnesses.json");

const ISSUE_59 = /(?:^59$|\/issues\/59$)/;
const PLAN_SECTIONS = ["callbacks", "hooks", "api", "props"];

export class ProbePlanError extends Error {
  constructor(message) {
    super(message);
    this.name = "ProbePlanError";
  }
}

/** The runtime names attached to holes owned by ticket 59. */
export const deriveProbePlan = (outcomes) => {
  const plan = Object.fromEntries(PLAN_SECTIONS.map((section) => [section, new Set()]));

  for (const entry of outcomes.exports ?? []) {
    if (entry.outcome !== "hole" || !ISSUE_59.test(String(entry.hole?.ticket ?? ""))) continue;
    if (!PLAN_SECTIONS.includes(entry.section)) continue;
    if (entry.witness?.kind !== "names") {
      throw new ProbePlanError(`${entry.export}: a probe-fed hole needs a name witness`);
    }
    for (const name of entry.witness.names ?? []) plan[entry.section].add(name);
  }

  return Object.fromEntries(PLAN_SECTIONS.map((section) => [section, [...plan[section]].sort()]));
};

export const compileProbePlan = (retiredHoles, classification, witnesses) => {
  const outcomes = coverageOutcomes(exportEntries(classification), {
    witnesses,
    holes: retiredHoles,
    traces: [],
  });
  const byExport = new Map(outcomes.exports.map((entry) => [entry.export, entry]));

  for (const hole of retiredHoles) {
    if (!ISSUE_59.test(String(hole.ticket ?? ""))) {
      throw new ProbePlanError("the durable probe source contains a hole not owned by issue 59");
    }
    for (const name of hole.exports) {
      const entry = byExport.get(name);
      if (!entry) throw new ProbePlanError(`${name}: the retired hole no longer joins the public census`);
      if (!PLAN_SECTIONS.includes(entry.section)) {
        throw new ProbePlanError(`${name}: ${entry.section} is not a probe-fed section`);
      }
      if (entry.witness?.kind !== "names") {
        throw new ProbePlanError(`${name}: the current witness no longer supplies runtime names`);
      }
    }
  }

  return deriveProbePlan(outcomes);
};

export const readProbePlan = () => {
  const parsed = JSON.parse(readFileSync(PROBE_PLAN, "utf8"));
  if (!Array.isArray(parsed.retiredHoles) || parsed.retiredHoles.length === 0) {
    throw new ProbePlanError(`${PROBE_PLAN}: retiredHoles must preserve the issue 59 hole inputs`);
  }
  const classification = JSON.parse(readFileSync(CLASSIFICATION, "utf8"));
  const witnesses = JSON.parse(readFileSync(WITNESSES, "utf8")).witnesses;
  return compileProbePlan(parsed.retiredHoles, classification, witnesses);
};

const sourceWith = (scenarios, capability) =>
  scenarios.find((scenario) => scenario.probeCapabilities.includes(capability)) ?? null;

const firstBaseline = (scenarios) =>
  scenarios.find((scenario) => scenario.id.startsWith("mount-baseline--") && scenario.variant === "plain") ?? null;

const clone = (source, variant, probeCallback = null) =>
  defineScenario({
    ...source,
    id: `${source.id}--probe-${variant}`,
    variant,
    probeCallback,
  });

const requireSource = (source, need) => {
  if (!source) {
    throw new ProbePlanError(
      `the probe plan needs a scenario with the ${need} capability, but the corpus declares none; ` +
        `dropping the probe would turn the hole into a silent pass`
    );
  }
  return source;
};

/** Selective variants, in observation-level order. */
export const probeVariants = (plainScenarios, plan) => {
  const variants = [];
  const callbacks = new Set(plan.callbacks ?? []);
  const props = new Set(plan.props ?? []);

  const knownCallbacks = new Set(["useOnSelectionChange", "useOnViewportChange"]);
  const unknownCallbacks = [...callbacks].filter((name) => !knownCallbacks.has(name));
  if (unknownCallbacks.length) throw new ProbePlanError(`no probe capability is defined for ${unknownCallbacks.join(", ")}`);

  const knownProps = new Set(["node-props", "edge-props", "edge-component-props", "connection-line-props"]);
  const unknownProps = [...props].filter((name) => !knownProps.has(name));
  if (unknownProps.length) throw new ProbePlanError(`no probe variant is defined for ${unknownProps.join(", ")}`);

  const needsFlowNode =
    (plan.hooks?.length ?? 0) > 0 ||
    (plan.api ?? []).includes("getState") ||
    props.has("node-props") ||
    callbacks.size > 0;

  if (callbacks.has("useOnSelectionChange")) {
    variants.push(
      clone(
        requireSource(sourceWith(plainScenarios, "selection"), "selection"),
        "flow-node",
        "useOnSelectionChange"
      )
    );
  }

  if (callbacks.has("useOnViewportChange")) {
    variants.push(
      clone(
        requireSource(sourceWith(plainScenarios, "viewport"), "viewport"),
        "flow-node",
        "useOnViewportChange"
      )
    );
  }

  if (needsFlowNode && callbacks.size === 0) {
    variants.push(clone(requireSource(firstBaseline(plainScenarios), "mount baseline"), "flow-node"));
  }

  if (props.has("edge-props") || props.has("edge-component-props")) {
    variants.push(clone(requireSource(firstBaseline(plainScenarios), "mount baseline"), "edge"));
  }

  if (props.has("connection-line-props")) {
    variants.push(clone(requireSource(sourceWith(plainScenarios, "connection"), "connection"), "connection-line"));
  }

  return variants;
};
