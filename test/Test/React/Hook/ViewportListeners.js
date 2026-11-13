import assert from 'node:assert/strict';
import { useOnViewportChange } from '../../index.js';
export { newRenderer } from '../Test.React.Hook.OnInitTiming/foreign.js';
export const publicViewportHook = useOnViewportChange;

export const checkListeners = create => {
  const session = create();
  const calls = [];
  // These fixtures are PS callbacks; the effect thunk is deliberate.
  const start = viewport => () => calls.push(['start', viewport]);
  const change = viewport => () => calls.push(['change', viewport]);
  const end = viewport => () => calls.push(['end', viewport]);
  const otherStart = viewport => () => calls.push(['other', viewport]);
  const first = { onStart: start, onChange: change, onEnd: end };
  session.first(first);
  assert.deepEqual(session.read(), first);
  assert.deepEqual(session.takeSnapshots(), [
    { onStart: start, onChange: undefined, onEnd: undefined },
    { onStart: start, onChange: change, onEnd: undefined },
    first,
  ], 'three independent effects update start, change, end in order');
  const viewport = { x: 1, y: 2, zoom: 3 };
  for (const handler of Object.values(session.read())) handler(viewport)();
  assert.deepEqual(calls, [['start', viewport], ['change', viewport], ['end', viewport]]);
  session.second({ onStart: otherStart });
  const partial = { onStart: otherStart, onChange: undefined, onEnd: undefined };
  assert.deepEqual(session.read(), partial, 'second caller clears unspecified slots');
  session.unmountSecond();
  assert.deepEqual(session.read(), partial, 'unmount does not clear source slots');
  session.first({ ...first });
  assert.deepEqual(session.read(), partial, 'new options object with unchanged handlers does not reinstall');
  const replaced = { ...first, onStart: otherStart };
  session.first(replaced);
  assert.deepEqual(session.read(), partial, 'changing start must leave unchanged change/end slots alone');
  const otherChange = viewport => () => calls.push(['other change', viewport]);
  session.first({ ...replaced, onChange: otherChange });
  assert.deepEqual(session.read(), { ...partial, onChange: otherChange }, 'each dependency updates its own slot');
  session.first({});
  assert.deepEqual(session.read(), { onStart: undefined, onChange: undefined, onEnd: undefined });
  session.unmountFirst();
  assert.deepEqual(session.read(), { onStart: undefined, onChange: undefined, onEnd: undefined });

  const jsSession = create();
  const jsCalls = [];
  const firstJs = {
    onStart: viewport => jsCalls.push(['start', viewport]),
    onChange: viewport => jsCalls.push(['change', viewport]),
    onEnd: viewport => jsCalls.push(['end', viewport]),
  };
  jsSession.firstJs(firstJs);
  for (const handler of Object.values(jsSession.read())) handler(viewport)();
  assert.deepEqual(jsCalls, [['start', viewport], ['change', viewport], ['end', viewport]], 'normal JS handlers run through index.js');
  jsSession.secondJs({ onStart: viewport => jsCalls.push(['other', viewport]) });
  const secondJsSlots = jsSession.read();
  assert.equal(secondJsSlots.onChange, undefined);
  assert.equal(secondJsSlots.onEnd, undefined);
  jsSession.firstJs({ ...firstJs });
  assert.deepEqual(jsSession.read(), secondJsSlots, 'JS conversion preserves unchanged handler dependencies');
  jsSession.unmountSecond();
  assert.deepEqual(jsSession.read(), secondJsSlots);
};
