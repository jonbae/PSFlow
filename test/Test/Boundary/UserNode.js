import assert from 'node:assert/strict';
import { newFakeRenderer } from '../Test.React.Hook.Store/foreign.js';

// The shared dispatcher is a test runtime, not a mock of node adoption. Reads
// exercise the real crossed instance/hook over the real store and reducer.
export const renderWithStore = (context, render) => newFakeRenderer(context)().render(render)();
export const consumerNode = { id: 'ps', position: { x: 0, y: 0 }, data: {} };

export const checkUserNode = create => {
  const marker = Symbol('consumer');
  const original = Object.freeze({ id: 'a', position: { x: 10, y: 20 }, data: {}, custom: {}, optional: undefined, [marker]: 1 });
  const session = create(original);
  const verify = expected => {
    const readings = session.read();
    for (const value of [readings.instance, readings.hook]) {
      assert.equal(value.internals.userNode, expected);
      assert.equal(value.internals.userNode.custom, expected.custom);
      assert.ok(Object.hasOwn(value.internals.userNode, 'optional'));
      assert.equal(value.position, expected.position);
    }
  };
  verify(original);
  const first = session.internalReference();
  session.replace(original);
  verify(original);
  assert.equal(session.internalReference(), first);
  const replacement = Object.freeze({ ...original, position: { x: 30, y: 40 }, custom: {} });
  session.replace(replacement);
  verify(replacement);
  assert.notEqual(session.internalReference(), first);

  // A forced adoption rebuilds internals even for the same user reference.
  const replaced = session.internalReference();
  session.readopt(true);
  assert.equal(session.internalReference(), replaced);
  session.readopt(false);
  verify(replacement);
  assert.notEqual(session.internalReference(), replaced);

  // Decoding must not cache values by original object identity: equality can
  // skip an internal rebuild, then a forced adoption must see fresh fields.
  const mutable = { ...original };
  const mutableSession = create(mutable);
  const oldPosition = mutable.position;
  mutable.position = { x: 70, y: 80 };
  mutableSession.replace(mutable);
  assert.equal(mutableSession.read().instance.position, oldPosition);
  assert.equal(mutableSession.read().instance.internals.userNode, mutable);
  mutableSession.readopt(false);
  assert.equal(mutableSession.read().instance.position, mutable.position);
};

export const checkRebuiltUserNodes = create => {
  const marker = Symbol('consumer');
  const original = Object.assign(Object.create({ inherited: true }), {
    id: 'a', position: { x: 0, y: 0 }, data: {}, custom: {},
    optional: undefined, ariaLabel: undefined, [marker]: 1,
    zIndex: 3.75, origin: Object.freeze([0, 0]), handles: Object.freeze([]),
    measured: Object.freeze({ width: 10, height: 20, previous: true }),
    width: 10, height: 20,
  });
  Object.defineProperty(original, '__proto__', { value: { consumer: true }, enumerable: true });
  Object.defineProperty(original, 'nonEnumerable', { value: true });
  Object.freeze(original);
  const untouched = Object.freeze({ id: 'untouched', position: { x: 0, y: 0 }, data: {}, custom: {} });
  const session = create(Object.freeze([original, untouched]));
  assert.equal(session.read()[0], original);

  const verify = expected => {
    const stored = session.read()[0];
    assert.deepEqual(stored, expected);
    assert.deepEqual(Reflect.ownKeys(stored), Reflect.ownKeys(expected));
    assert.equal(stored.custom, expected.custom, 'rebuilt nodes must retain consumer field references');
    assert.equal(stored.position, expected.position);
    assert.equal(stored.origin, expected.origin);
    assert.equal(stored.handles, expected.handles);
    assert.equal(session.read()[1], untouched, 'untouched nodes keep their original identity');
    for (const internal of Object.values(session.internal())) {
      assert.equal(internal.internals.userNode, stored);
      assert.equal(internal.custom, expected.custom);
      assert.equal(internal[marker], expected[marker]);
    }
    let clicked;
    session.click((_event, node) => { clicked = node; });
    assert.deepEqual(clicked, expected);
    assert.equal(clicked.custom, expected.custom, 'later callbacks must retain consumer fields after uncontrolled changes');
    assert.notEqual(clicked, stored, 'mouse callbacks receive a shallow copy');
    let deleted;
    session.deleted(nodes => { deleted = nodes; });
    assert.equal(deleted[0], stored, 'delete callbacks receive the rebuilt consumer node');
    assert.equal(deleted[1], untouched);
    return stored;
  };

  let expected = { ...original, selected: true };
  session.change([{ type: 'select', id: 'a', selected: true }]);
  let previous = verify(expected);
  assert.notEqual(previous, original);
  const position = Object.freeze({ x: 30, y: 40 });
  expected = { ...expected, position, dragging: true };
  session.change([{ type: 'position', id: 'a', position, dragging: true }]);
  const moved = verify(expected);
  assert.notEqual(moved, previous);
  assert.equal(previous.position, original.position, 'later changes do not mutate earlier nodes');

  // Measurement and resize updates must retain the node's extra fields while
  // replacing measured itself, including changes that set just one attribute.
  for (const setAttributes of [undefined, false, 'width', 'height', true]) {
    const dimensions = Object.freeze({ width: 50, height: 60, extra: undefined, [marker]: 'measured' });
    const previousMeasured = session.read()[0].measured;
    expected = { ...expected, measured: { ...dimensions }, resizing: true };
    if (setAttributes === true || setAttributes === 'width') expected.width = dimensions.width;
    if (setAttributes === true || setAttributes === 'height') expected.height = dimensions.height;
    session.change([{ type: 'dimensions', id: 'a', dimensions, setAttributes, resizing: true }]);
    const resized = verify(expected);
    assert.notEqual(resized.measured, dimensions);
    assert.notEqual(resized.measured, previousMeasured);
  }
  expected = { ...expected, selected: false, dragging: false, resizing: false };
  session.change([
    { type: 'select', id: 'a', selected: false },
    { type: 'position', id: 'a', dragging: false },
    { type: 'dimensions', id: 'a', resizing: false },
  ]);
  previous = verify(expected);
  for (const changes of [[], [{ type: 'select', id: 'missing', selected: true }]]) {
    session.change(changes);
    assert.equal(verify(expected), previous);
  }
  for (const type of ['position', 'dimensions']) {
    session.change([{ type, id: 'a' }]);
    const copied = verify(expected);
    assert.notEqual(copied, previous, 'a change without fields still copies the affected node');
    previous = copied;
  }

  // Add/replace copy their own consumer object. Subsequent internal changes
  // retain its fields, and a replacement does not inherit the old extras.
  const replacement = Object.freeze({ id: 'a', position: { x: 5, y: 6 }, data: {}, custom: {}, [marker]: 2 });
  session.change([{ type: 'replace', id: 'a', item: replacement }, { type: 'select', id: 'a', selected: true }]);
  previous = verify(replacement);
  assert.notEqual(previous, replacement);
  expected = { ...replacement, selected: true };
  session.change([{ type: 'select', id: 'a', selected: true }]);
  verify(expected);
  session.change([{ type: 'remove', id: 'a' }, { type: 'add', item: original, index: 0 }]);
  assert.notEqual(verify({ ...original }), original);
  session.change([{ type: 'select', id: 'a', selected: true }]);
  verify({ ...original, selected: true });
  assert.equal(original.selected, undefined);
  assert.equal(original.position.x, 0);
};
