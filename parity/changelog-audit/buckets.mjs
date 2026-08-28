// The audit's buckets, and the rule each one has to satisfy to stay an audit
// rather than a list of assertions.
//
// Split out of `audit.mjs` for one reason: `gate-pending` is checkable in a way
// the older buckets were not. A covered bucket's evidence is a string a reviewer
// has to open a file to dispute; a `gate-pending` row's scenario is a **name**,
// and either the corpus holds it or it does not. That check wants tests, and
// tests want the rules to be a function of a row rather than a walk over the
// whole verdict file with a report being written on the side.
//
// ## The three kinds, and what each is for
//
// **covered** — the change needs no action *and* the row names the artifact that
// makes that true. Evidence required.
//
// **gap** — the change is not proven. Three of them, and the distinction is what
// this file exists for: `ported-ungated` is a silent gap with no plan,
// `gate-pending` is a gap with a named gate coming, and `not-ported` is behavior
// absent from PSFlow. A gap is never a covered bucket, however good the plan —
// that is rule 4 of `tickets/080-test-debt-dispositions.md`, and it is the whole
// reason `gate-pending` had to be a third gap rather than a flavour of covered.
//
// **accepted** — the change is implemented and nothing will ever gate it, by
// decision. A written reason required, and the reason is the point: it is what
// lets the *gap* count reach zero without anything being called covered that is
// not.
//
// (`na` is the fourth and is not a kind in that sense — it is for changes with
// no possible PSFlow analogue, which are neither proven nor unproven.)

/**
 * Bucket keys are gate names where a gate is what proves the change, deliberately:
 * a covered bucket says which gate would go red. `smoke` is absent because no
 * in-range PR is covered by `smoke.spec.ts` — an empty bucket is carried only
 * where something already points at it.
 *
 * `system` is the exception that proves that rule. It holds no row today and is
 * carried anyway, because fifty `gate-pending` rows name it as their target: it
 * is where they graduate, and `target` is what says so. A bucket nothing can
 * name and nothing holds would be the empty bucket the rule refuses.
 */
export const BUCKETS = {
  docs: { kind: "covered", label: "Docs / types / tooling only — no runtime behavior" },
  "ts-only": { kind: "covered", label: "TypeScript-only (type signature, generics, inference)" },
  surface: { kind: "covered", target: true, label: "Surface change — gated by parity:surface" },
  function: {
    kind: "covered",
    target: true,
    label: "Pure-math change — gated by function parity, differential against the @psflow/oracle bundle",
  },
  conformance: { kind: "covered", target: true, label: "Behavior covered by a spec in the conformance test suite" },
  unit: { kind: "covered", target: true, label: "Behavior covered by a PureScript unit/property test" },
  system: { kind: "covered", target: true, label: "Behavior driven by the dual-run net — gated by parity:system" },
  "gate-pending": { kind: "gap", label: "Ported and ungated, with a named gate coming (a gap, never a covered bucket)" },
  "ported-ungated": { kind: "gap", label: "Ported and correct, but no gate exercises it and none is planned (test debt)" },
  "not-ported": { kind: "gap", label: "Behavior not present in PSFlow" },
  "accepted-ungated": { kind: "accepted", label: "Ported, and deliberately never gated — carries the written reason" },
  "n/a": { kind: "na", label: "No PSFlow analogue (Svelte-only, build tooling, infra)" },
};

/** The boundary staging is 1–4, counted in converters (`src/Boundary.purs`). */
const STAGES = [1, 2, 3, 4];

/** The gate whose rows are driven by the net, and so name a corpus scenario. */
const NET = "system";

/** Buckets a `gate-pending` row may name as the one it will graduate into. */
const targets = () => Object.keys(BUCKETS).filter((bucket) => BUCKETS[bucket].target);

const filled = (value) => String(value ?? "").trim().length > 0;

/**
 * A field carried by a bucket that does not use it. Reported rather than
 * ignored: the way this file goes wrong is a row rebucketed away from
 * `gate-pending` that kept its `scenario`, which nothing then reads and which
 * goes on reading as a plan forever.
 */
const stray = (row, field, allowed) =>
  row[field] !== undefined && row[field] !== null && row.bucket !== allowed
    ? `carries \`${field}\`, which only a "${allowed}" row uses`
    : null;

/**
 * Everything wrong with one row, as sentences.
 *
 * `scenarios` is the corpus's **name space**: `written` are the ids scenarios
 * exist under today, `reserved` are the ids `parity/system/corpus/reserved.mjs`
 * holds for scenarios a later ticket will write. Both count as resolving — a
 * reserved id is a name the corpus has committed to, and the register is gated
 * so no other source can take it — and the two are reported apart, because
 * "planned against a name nobody has written yet" is a true thing to say about
 * fifty rows and a false thing to hide.
 *
 * Pass no `scenarios` and the join is skipped, which is only for callers that
 * cannot assemble the corpus. The audit is not one of them: it fails outright
 * rather than passing a row whose name it could not check.
 */
export const rowProblems = (pr, row, { scenarios = null } = {}) => {
  const said = [];
  const say = (problem) => said.push(`#${pr}: ${problem}`);

  const meta = BUCKETS[row.bucket];
  if (!meta) return [`#${pr}: unknown bucket "${row.bucket}"`];

  if (meta.kind === "covered" && !filled(row.evidence)) {
    say(`bucket "${row.bucket}" is a covered bucket and requires non-empty evidence`);
  }
  if (meta.kind === "gap" && !row.ticket && !filled(row.note)) {
    say(`bucket "${row.bucket}" is a gap and requires a ticket or a note recording the in-branch fix`);
  }
  if (meta.kind === "accepted" && !filled(row.reason)) {
    say(`bucket "${row.bucket}" is an accepted bucket and requires a written reason`);
  }

  for (const problem of [
    stray(row, "gate", "gate-pending"),
    stray(row, "scenario", "gate-pending"),
    stray(row, "stage", "gate-pending"),
    stray(row, "test", "gate-pending"),
    stray(row, "reason", "accepted-ungated"),
  ]) {
    if (problem) say(problem);
  }

  if (row.bucket === "gate-pending") said.push(...pendingProblems(pr, row, scenarios));

  return said;
};

/**
 * The three things a `gate-pending` row has to name, and the fourth it has to
 * resolve.
 *
 * The boundary stage is required of net-bound rows only, and refused of the
 * others, which is what the glossary's "where the target is the net" means: a
 * stage says how much of the JS surface has crossed, and a row bound for a
 * PureScript unit test is not waiting on any of it. Requiring one anyway would
 * be asking for a made-up number, which is the failure this bucket exists to
 * prevent.
 */
const pendingProblems = (pr, row, scenarios) => {
  const said = [];
  const say = (problem) => said.push(`#${pr}: gate-pending row ${problem}`);
  const net = row.gate === NET;

  if (!filled(row.gate)) {
    say(`names no target gate — one of ${targets().map((t) => `"${t}"`).join(", ")}`);
  } else if (!BUCKETS[row.gate]?.target) {
    say(`names "${row.gate}" as its target gate, and that cannot be a gate-pending row's target: a row graduates into a covered bucket, one of ${targets().map((t) => `"${t}"`).join(", ")}`);
  }

  if (net) {
    if (!filled(row.scenario)) say("names no scenario, so nothing joins it to the corpus");
    if (!STAGES.includes(row.stage)) {
      say(
        `names no boundary stage in ${STAGES[0]}–${STAGES[STAGES.length - 1]}, and a net-bound row is blocked ` +
          "until the stage that crosses what it drives has landed"
      );
    }
    if (row.test !== undefined) say("names a test as well as a scenario; the net drives scenarios");
  } else if (filled(row.gate)) {
    if (!filled(row.test)) say(`names no test, and a "${row.gate}" row is proven by one rather than by a scenario`);
    if (row.scenario !== undefined) say(`names a scenario, but only a "${NET}" row is driven by one`);
    if (row.stage !== undefined) {
      say(`names a boundary stage, which only a "${NET}" row waits on — a ${row.gate} test is not blocked by the crossing`);
    }
  }

  if (net && filled(row.scenario) && scenarios) {
    const known = [...(scenarios.written ?? []), ...(scenarios.reserved ?? [])];
    if (!known.includes(row.scenario)) {
      say(
        `names the scenario \`${row.scenario}\`, which the corpus neither holds nor reserves. ` +
          "The name means nothing until it does — write the scenario, reserve the id, or correct the row"
      );
    }
  }

  return said;
};
