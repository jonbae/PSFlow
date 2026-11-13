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
