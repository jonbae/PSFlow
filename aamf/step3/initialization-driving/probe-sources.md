# Clock API reference used for diagnostics

Pinned local implementation/types: Playwright 1.60.0, `node_modules/playwright-core/types/types.d.ts` Clock interface.

Official primary references checked November 10, 2026:

- https://playwright.dev/docs/clock
- https://playwright.dev/docs/api/class-clock#clock-run-for

`install` must precede application clock use and overrides timers, animation/idle callbacks, Date and performance. `runFor` fires elapsed callbacks; `fastForward` can skip repeated callbacks and is unsuitable for preserving frame counts. Virtual timers do not replace native layout/resize-observer delivery. No production clock behavior is changed by these diagnostic probes.
