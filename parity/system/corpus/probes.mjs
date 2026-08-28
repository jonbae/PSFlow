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

const here = dirname(fileURLToPath(import.meta.url));
export const PROBE_PLAN = join(here, "probe-plan.json");

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

export const readProbePlan = () => {
  const parsed = JSON.parse(readFileSync(PROBE_PLAN, "utf8"));
  const plan = {};
  for (const section of PLAN_SECTIONS) {
    if (!Array.isArray(parsed[section]) || parsed[section].some((name) => typeof name !== "string" || name === "")) {
      throw new ProbePlanError(`${PROBE_PLAN}: ${section} must be a list of runtime names`);
    }
    plan[section] = [...new Set(parsed[section])].sort();
  }
  return plan;
};

const sourceWith = (scenarios, capability) =>
  scenarios.find((scenario) => scenario.probeCapabilities.includes(capability)) ?? null;

const firstBaseline = (scenarios) =>
  scenarios.find((scenario) => scenario.id.startsWith("mount-baseline--") && scenario.variant === "plain") ?? null;

const clone = (source, variant) =>
  defineScenario({
    ...source,
    id: `${source.id}--probe-${variant}`,
    variant,
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
    callbacks.has("useOnSelectionChange");

  if (needsFlowNode) {
    const source = callbacks.has("useOnSelectionChange")
      ? requireSource(sourceWith(plainScenarios, "selection"), "selection")
      : requireSource(firstBaseline(plainScenarios), "mount baseline");
    variants.push(clone(source, "flow-node"));
  }

  if (callbacks.has("useOnViewportChange")) {
    variants.push(clone(requireSource(sourceWith(plainScenarios, "viewport"), "viewport"), "flow-node"));
  }

  if (props.has("edge-props") || props.has("edge-component-props")) {
    variants.push(clone(requireSource(firstBaseline(plainScenarios), "mount baseline"), "edge"));
  }

  if (props.has("connection-line-props")) {
    variants.push(clone(requireSource(sourceWith(plainScenarios, "connection"), "connection"), "connection-line"));
  }

  return variants;
};
