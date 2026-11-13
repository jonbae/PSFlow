// `useKeyPress`, entered from JavaScript, against upstream.
//
// Each check mounts one library's `useKeyPress` and fires one script of key
// events at the hook's target, as a browser delivers them, then does the same
// for the other library. After each event it records what the hook answers
// and whether the event's default was prevented. The two records must match,
// and upstream's is written out as well, so a hook that never answers can't
// pass by matching itself.
//
// Three upstream changes each have a check:
//
// * #5090: a key is released even when an input is focused.
// * #5118: Alt counts as a modifier, and a press on a focused button or link
//   isn't swallowed unless a modifier is held.
// * #5263: `actInsideInputWithModifier` defaults to `true`, so a key pressed
//   with a modifier counts while an input is focused.
//
// The hook renders nothing, so React touches no DOM beyond the root container.
// The stubs that follow are that much of a DOM, and an event target for the
// hook to listen on. Upstream reads `document` when its module loads, so both
// libraries are imported after the stubs are in place.
import assert from 'node:assert/strict';
import test from 'node:test';

class EventTargetStub {
  constructor(label) {
    this.label = label;
    this.listeners = new Map();
  }
  addEventListener(type, listener) {
    if (!this.listeners.has(type)) this.listeners.set(type, new Set());
    this.listeners.get(type).add(listener);
  }
  removeEventListener(type, listener) {
    this.listeners.get(type)?.delete(listener);
  }
  dispatch(type, event) {
    for (const listener of [...(this.listeners.get(type) ?? [])]) listener(event);
  }
  listenerCount() {
    return [...this.listeners.values()].reduce((n, set) => n + set.size, 0);
  }
}

const document = Object.assign(new EventTargetStub('document'), { activeElement: null, body: null });
globalThis.document = document;
globalThis.window = Object.assign(new EventTargetStub('window'), {
  document,
  event: undefined,
  HTMLIFrameElement: class {},
});
globalThis.IS_REACT_ACT_ENVIRONMENT = true;
const { window } = globalThis;
// A consumer's own element, for the `target` option.
const panel = new EventTargetStub('panel');

const { act, createElement: h } = await import('react');
const { createRoot } = await import('react-dom/client');
const upstream = await import('@xyflow/react');
const psflow = await import('../../index.js');

const sides = [
  ['upstream', upstream],
  ['psflow', psflow],
];

const container = () => ({
  nodeType: 1,
  tagName: 'DIV',
  namespaceURI: null,
  ownerDocument: document,
  textContent: '',
  addEventListener() {},
  removeEventListener() {},
});

// What a key event can be dispatched at, in the members `isInputDOMNode` and
// the interactive-element check read.
const element = (nodeName, attributes = []) => ({
  nodeType: 1,
  nodeName,
  hasAttribute: (name) => attributes.includes(name),
  closest: () => null,
});
const body = element('DIV');
const input = element('INPUT');
const button = element('BUTTON');

const keyEvent = (key, code, { on = body, ctrl = false, meta = false, shift = false, alt = false } = {}) => ({
  key,
  code,
  ctrlKey: ctrl,
  metaKey: meta,
  shiftKey: shift,
  altKey: alt,
  target: on,
  composedPath: () => [on],
  defaultPrevented: false,
  preventDefault() {
    this.defaultPrevented = true;
  },
});

// Steps. A key event bubbles from the element through the consumer's panel,
// when it's inside it, to the document and then the window, which is where a
// browser delivers it to each kind of target.
const down = (key, code, how) => ['keydown', keyEvent(key, code, how)];
const up = (key, code, how) => ['keyup', keyEvent(key, code, how)];
const blur = () => ['blur', { preventDefault() {} }];

function fire(type, event, insidePanel) {
  if (type === 'blur' || type === 'contextmenu') return window.dispatch(type, event);
  if (insidePanel) panel.dispatch(type, event);
  document.dispatch(type, event);
  window.dispatch(type, event);
}

// Mount the hook, run the steps, and report the hook's answer after each,
// with `!` for an event whose default was prevented.
function record(library, { keyCode, options, insidePanel = false }, steps) {
  const answers = [];
  function Probe() {
    answers.push(library.useKeyPress(keyCode, options()));
    return null;
  }
  const listeners = () => document.listenerCount() + window.listenerCount() + panel.listenerCount();
  const before = listeners();
  const root = createRoot(container());
  act(() => root.render(h(Probe)));
  const trace = [];
  for (const step of steps) {
    // Each step builds its event afresh, so the two libraries never share one.
    const [type, event] = step();
    act(() => fire(type, event, insidePanel));
    trace.push(`${answers.at(-1)}${event.defaultPrevented ? '!' : ''}`);
  }
  act(() => root.unmount());
  // React adds a listener of its own to the document the first time it mounts.
  return { trace, left: listeners() - before };
}

function compare(hook, steps, expected) {
  const [up, ps] = sides.map(([, library]) => record(library, hook, steps));
  assert.deepEqual(up.trace, expected, "upstream's own trace");
  assert.deepEqual(ps.trace, up.trace);
  assert.equal(ps.left, 0, 'ps-flow removed every listener on unmount');
}

const noOptions = { options: () => undefined };

test('#5090: a key pressed outside an input is released by a keyup inside one', () => {
  compare(
    { keyCode: 'a', ...noOptions },
    [() => down('a', 'KeyA'), () => up('a', 'KeyA', { on: input })],
    ['true!', 'false']
  );
});

test('#5118: Alt held in an input counts as a modifier', () => {
  compare(
    { keyCode: 'a', ...noOptions },
    [() => down('a', 'KeyA', { on: input, alt: true }), () => up('a', 'KeyA', { on: input })],
    ['true!', 'false']
  );
});

test("#5118: a press on a focused button isn't swallowed, unless a modifier is held", () => {
  compare(
    { keyCode: ['Enter', 'Meta+Enter'], ...noOptions },
    [
      () => down('Enter', 'Enter', { on: button }),
      () => up('Enter', 'Enter', { on: button }),
      () => down('Meta', 'MetaLeft', { on: button, meta: true }),
      () => down('Enter', 'Enter', { on: button, meta: true }),
    ],
    ['true', 'false', 'false', 'true!']
  );
});

test('#5263: with no options, a key pressed with a modifier counts in an input', () => {
  compare(
    { keyCode: 'Meta', ...noOptions },
    [() => down('Meta', 'MetaLeft', { on: input, meta: true }), () => up('Meta', 'MetaLeft', { on: input })],
    ['true!', 'false']
  );
});

test('#5263: an options object without actInsideInputWithModifier, or with null, takes true', () => {
  for (const options of [{}, { actInsideInputWithModifier: null }, { target: null }]) {
    compare(
      { keyCode: 'Shift', options: () => options },
      [() => down('Shift', 'ShiftLeft', { on: input, shift: true })],
      ['true!']
    );
  }
});

test('actInsideInputWithModifier: false, as the delete key has it, ignores the input', () => {
  compare(
    { keyCode: 'Backspace', options: () => ({ actInsideInputWithModifier: false }) },
    [
      () => down('Backspace', 'Backspace', { on: input }),
      () => down('Backspace', 'Backspace', { on: input, meta: true }),
      () => down('Backspace', 'Backspace'),
    ],
    ['false', 'false', 'true!']
  );
});

test('preventDefault: false prevents nothing, and only false does', () => {
  compare(
    { keyCode: 'a', options: () => ({ preventDefault: false }) },
    [() => down('a', 'KeyA')],
    ['true']
  );
  compare(
    { keyCode: 'a', options: () => ({ preventDefault: 0 }) },
    [() => down('a', 'KeyA')],
    ['true!']
  );
});

test('a code is matched by the event code, so Space is pressed', () => {
  compare(
    { keyCode: 'Space', ...noOptions },
    [() => down(' ', 'Space'), () => up(' ', 'Space')],
    ['true!', 'false']
  );
});

test('a combination is pressed once all of its keys are held, and released by either', () => {
  compare(
    { keyCode: 'Meta+s', ...noOptions },
    [
      () => down('Meta', 'MetaLeft', { meta: true }),
      () => down('s', 'KeyS', { meta: true }),
      () => up('s', 'KeyS', { meta: true }),
      () => up('Meta', 'MetaLeft'),
    ],
    ['false', 'true!', 'false', 'false']
  );
});

test("a single key isn't pressed while another key is held", () => {
  compare(
    { keyCode: 'Shift', ...noOptions },
    [() => down('a', 'KeyA'), () => down('Shift', 'ShiftLeft', { shift: true })],
    ['false', 'false']
  );
});

test("releasing Meta releases every key, for the keyup a Mac doesn't send", () => {
  compare(
    { keyCode: 'a', ...noOptions },
    [
      () => down('Meta', 'MetaLeft', { meta: true }),
      () => down('s', 'KeyS', { meta: true }),
      () => up('Meta', 'MetaLeft'),
      () => down('a', 'KeyA'),
    ],
    ['false', 'false', 'false', 'true!']
  );
});

test('a window blur releases the key', () => {
  compare(
    { keyCode: 'a', ...noOptions },
    [() => down('a', 'KeyA'), blur, () => up('a', 'KeyA')],
    ['true!', 'false', 'false']
  );
});

test("an empty array listens for no key, whatever the event's code", () => {
  compare({ keyCode: [], ...noOptions }, [() => down('', '')], ['false']);
});

test('the target option listens on that element, and the window as well as the document', () => {
  compare(
    { keyCode: 'a', options: () => ({ target: panel }), insidePanel: true },
    [() => down('a', 'KeyA'), () => up('a', 'KeyA')],
    ['true!', 'false']
  );
  compare(
    { keyCode: 'a', options: () => ({ target: window }) },
    [() => down('a', 'KeyA'), () => up('a', 'KeyA')],
    ['true!', 'false']
  );
});

test('a hook with no key code answers false and listens for nothing', () => {
  compare({ keyCode: null, ...noOptions }, [() => down('a', 'KeyA')], ['false']);
  compare({ keyCode: undefined, ...noOptions }, [() => down('a', 'KeyA')], ['false']);
});
