---
name: hdd-work
description: Advance one HDD issue far enough to produce durable progress or evidence.
disable-model-invocation: true
---

# Work one hypothesis

Take a single issue and push it until it has produced something durable — implementation that compiles, evidence that settles a question, or a precise new question that did not exist before.

You are usually running in your own context, and **it will be discarded when you report back**. Whatever matters and reaches only this window is lost. That makes externalizing to GitHub the job, not the paperwork.

Read [`../hdd/VOCABULARY.md`](../hdd/VOCABULARY.md) for the terms and labels, and [`../hdd/GRAPH.md`](../hdd/GRAPH.md) when you need to write to the graph.

## 1. Read the issue

```bash
gh issue view <n> --comments --json number,title,body,labels,comments
```

The issue's work label decides how you behave. It is the classification of record — read it off GitHub rather than from whatever the prompt implied, so one issue means one thing to everyone who opens it.

Read the parent hypothesis too (`Part of #<n>`): its **Fog** section is the uncertainty you are working inside.

## 2. Work it, according to the label

**`hdd:implementation`** — an oracle already decides correctness. Inspect the code, sketch the types, leave `?todo` holes where an implementation is missing, and compile: a build that succeeds with holes throughout proves the composition is coherent and tells you the exact type of everything still missing. Fill holes against those types, run the tests and properties, commit as you go.

**`hdd:exploration`** — the space is unclear, so buy information. Prototype rival shapes, probe the architecture's boundaries, and try to *falsify* rather than confirm: a probe that could only have succeeded taught you nothing. Divergence between attempts is the signal — it marks where the design is genuinely open. Commit the experiments; they are evidence.

**`hdd:research`** — the missing knowledge is external. Go to primary sources: the library's own source, the specification, first-party documentation. Follow each claim back to whoever owns it. The output is knowledge, so it lands as a comment on the issue with citations, not as code.

**`hdd:task`** — do the mechanical work, and say what it revealed if it revealed anything.

**`hdd:hitl`** — the answer belongs to a human. Sharpen the question and lay out the options with what each would cost, then hand it back. An invented answer here is indistinguishable from a real one downstream, which is precisely why the label exists.

## 3. Externalize before you stop

Sort everything you learned:

- **Precise enough for someone else to act on** → file it as an issue now ([`GRAPH.md`](../hdd/GRAPH.md)), linked to the parent hypothesis.
- **Real but still vague** → add it to the parent hypothesis's **Fog** section.
- **Evidence** → a commit, or a comment on the issue with the numbers, the counterexample, or the citation.

The precision test — and the difference between the two — is in `VOCABULARY.md`.

## When the contract is the problem

Repeated failure against the same constraint is diagnostic. Once the same wall has stopped three attempts, the contract itself is the suspect — the types, the signature, or the requirement it encodes.

Preserve what the failures showed, report the contract problem, and let it be resolved by exploration or by a human. Bending the contract until the tests agree with the implementation destroys the only independent check on whether the thing is right, and the tests will pass either way.

## Report back

State: what you did, the branch and commits, the evidence, the issue numbers you filed, the fog you recorded, anything blocking, and whether the issue is resolved.

You are finished when every precise thing you learned is an issue, every vague thing is fog on the parent, and every piece of evidence is a commit or a comment — and nothing that matters is left only in this context.
