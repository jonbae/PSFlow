import assert from 'node:assert/strict';

// Local proxy at Boundary.Utils' callable seam. Expected identities and keys
// are the consumer contract, not a reconstruction of the change algorithm.
export const checkConsumerObjects = (applyNodes, applyEdges, addEdge) => {
  const symbol = Symbol('consumer');
  const original = Object.freeze({ id: 'a', position: { x: 0, y: 0 }, data: {}, source: 'a', target: 'b', custom: {}, optional: undefined, [symbol]: 1 });
  for (const apply of [applyNodes, applyEdges]) {
    const untouched = { ...original, id: 'untouched' };
    assert.equal(apply([], [original])[0], original);
    const selected = apply([{ type: 'select', id: 'a', selected: true }], [original, untouched]);
    assert.notEqual(selected[0], original);
    assert.equal(selected[1], untouched);
    assert.equal(selected[0].custom, original.custom);
    assert.equal(selected[0][symbol], 1);
    assert.ok(Object.hasOwn(selected[0], 'optional'));
    assert.equal(selected[0].selected, true);
    const replacement = { ...original, id: 'replacement' };
    const next = apply([
      { type: 'replace', id: 'a', item: replacement },
      { type: 'remove', id: 'untouched' },
      { type: 'add', item: original, index: 0 },
    ], [original, untouched]);
    assert.deepEqual(next.map(n => n.id), ['a', 'replacement']);
    assert.notEqual(next[0], original);
    assert.notEqual(next[1], replacement);
    assert.ok(Object.hasOwn(next[1], 'optional'));
  }
  const existing = { id: 'existing', source: 'x', target: 'y' };
  const edges = [existing];
  const added = addEdge(original, edges);
  assert.equal(added[0], existing);
  assert.notEqual(added[1], original);
  assert.equal(added[1].custom, original.custom);
  assert.ok(Object.hasOwn(added[1], 'optional'));
  assert.equal(addEdge(original, added), added);
  assert.equal(addEdge({ source: '', target: 'b' }, edges, { onError() {} }), edges);
};
