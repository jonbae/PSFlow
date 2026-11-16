// The in-page half of the boundary's browser differential.
//
// `harness.mjs` bundles this file twice, once with `@xyflow/react` resolving
// to upstream and once to ps-flow's `index.js`, and loads each bundle into
// its own page. A case table, bundled with it, names what to mount. Running a
// case mounts `<ReactFlow />` with the case's props and children, lets its
// effects, its measurements and its first frames settle, optionally drives
// it, and returns what a consumer can read back: the store's state and
// lookups, the rendered DOM, the callbacks it fired and what it printed.
//
// Cases are data plus functions, so they live in the bundle rather than
// crossing from node: a function cannot be handed to `page.evaluate`.
import * as library from '@xyflow/react';
import { createElement as h } from 'react';
import { createRoot } from 'react-dom/client';
import { flushSync } from 'react-dom';
import { serializeValue } from '../../system/harness/serialize.mjs';
import cases from 'contract:cases';

const printed = [];
for (const level of ['error', 'warn']) {
  const original = console[level].bind(console);
  console[level] = (...args) => {
    printed.push({ level, text: args.map(String).join(' ') });
    original(...args);
  };
}
window.addEventListener('error', (event) => printed.push({ level: 'pageerror', text: event.message }));

const frame = () => new Promise((resolve) => requestAnimationFrame(() => resolve()));
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Effects, the resize observer's first measurement, the frame after it and
// `onInit`'s one-millisecond timer.
async function settle() {
  for (let i = 0; i < 3; i++) await frame();
  await sleep(30);
  for (let i = 0; i < 2; i++) await frame();
}

// The net's DOM rule: attributes as a set, class tokens and style
// declarations sorted.
function serializeElement(element) {
  const attrs = {};
  for (const { name, value } of [...element.attributes].sort((a, b) => (a.name < b.name ? -1 : 1))) {
    if (name === 'class') attrs[name] = value.split(/\s+/).filter(Boolean).sort().join(' ');
    else if (name === 'style') attrs[name] = value.split(';').map((d) => d.trim()).filter(Boolean).sort().join('; ');
    else attrs[name] = value;
  }
  const children = [];
  let text = '';
  for (const child of element.childNodes) {
    if (child.nodeType === Node.ELEMENT_NODE) children.push(serializeElement(child));
    else if (child.nodeType === Node.TEXT_NODE) text += child.textContent;
  }
  return { tag: element.tagName.toLowerCase(), attrs, ...(text ? { text } : {}), children };
}

const withoutTimeStamps = (value) => {
  if (Array.isArray(value)) return value.map(withoutTimeStamps);
  if (value === null || typeof value !== 'object') return value;
  return Object.fromEntries(Object.entries(value).filter(([key]) => key !== 'timeStamp').map(([key, v]) => [key, withoutTimeStamps(v)]));
};

const entries = (map) =>
  [...map.entries()].map(([key, value]) => [key, value instanceof Map ? entries(value) : serializeValue(value, { maxDepth: 24 })]);

function readState(state, omit) {
  const plain = {};
  for (const key of Object.keys(state)) {
    if (omit.includes(key) || state[key] instanceof Map) continue;
    plain[key] = state[key];
  }
  return {
    state: serializeValue(plain, { maxDepth: 24 }),
    nodeLookup: entries(state.nodeLookup),
    parentLookup: entries(state.parentLookup),
    edgeLookup: entries(state.edgeLookup),
    connectionLookup: entries(state.connectionLookup),
  };
}

const graph = () => ({
  nodes: [
    { id: 'a', type: 'input', position: { x: 0, y: 0 }, data: { label: 'A' } },
    { id: 'b', position: { x: 200, y: 120 }, data: { label: 'B' } },
    { id: 'c', type: 'output', position: { x: 0, y: 240 }, data: { label: 'C' } },
  ],
  edges: [
    { id: 'a-b', source: 'a', target: 'b' },
    { id: 'b-c', source: 'b', target: 'c', label: 'to c' },
  ],
});

const container = document.getElementById('root');
let root = null;

window.contract = {
  names: () => cases.map((c) => c.name),
  async run(name) {
    const contract = cases.find((c) => c.name === name);
    if (!contract) throw new Error(`no case named ${JSON.stringify(name)}`);
    printed.length = 0;
    const calls = [];
    // A DOM event's `timeStamp` is a clock reading, which the net's
    // normalization deletes for the same reason.
    const record = (label) => (...args) => {
      calls.push({ name: label, args: withoutTimeStamps(serializeValue(args, { maxDepth: 24 })) });
    };
    const seen = {};
    function Probe() {
      seen.api = library.useStoreApi();
      seen.instance = library.useReactFlow();
      return null;
    }
    const context = { library, h, record, graph, frame, sleep, settle, seen, side: __SIDE__, container };
    const props = { ...graph(), ...(contract.props?.(context) ?? {}) };
    const children = contract.children?.(context) ?? null;

    root = createRoot(container);
    try {
      flushSync(() => root.render(h(library.ReactFlow, props, children, h(Probe))));
    } catch (error) {
      printed.push({ level: 'threw', text: error.message });
    }
    await settle();
    if (contract.wait) await sleep(contract.wait);
    let driven = null;
    if (contract.drive && seen.api) {
      try {
        driven = serializeValue(await contract.drive(context), { maxDepth: 24 });
      } catch (error) {
        driven = { threw: error.message };
      }
      await settle();
      if (contract.wait) await sleep(contract.wait);
    }
    const result = {
      ...(seen.api ? readState(seen.api.getState(), contract.omit ?? []) : { state: null }),
      dom: container.firstElementChild ? serializeElement(container.firstElementChild) : null,
      driven,
      calls,
      console: [...printed],
    };
    await contract.after?.(context);
    root.unmount();
    root = null;
    container.innerHTML = '';
    return contract.observe ? contract.observe(result) : result;
  },
};
