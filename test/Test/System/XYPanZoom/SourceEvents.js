"use strict";

export const mkPinchSpy = () => {
  const currentTarget = {
    clientLeft: 2,
    clientTop: 3,
    getBoundingClientRect: () => ({ left: 10, top: 20 }),
  };
  const event = {
    ctrlKey: true,
    deltaY: 100,
    deltaMode: 0,
    clientX: 95,
    clientY: 84,
    currentTarget,
    target: { closest: () => null },
    preventDefault() {},
    stopImmediatePropagation() {},
  };
  const selection = { property: (name) => name === "__zoom" ? { x: 0, y: 0, k: 1 } : null };
  let call = null;
  const behavior = {
    scaleTo(actualSelection, zoom, point, sourceEvent) {
      call = { actualSelection, zoom, point, sourceEvent };
    },
  };
  return {
    behavior,
    selection,
    event,
    sawExpectedCall: () =>
      call !== null &&
      call.actualSelection === selection &&
      call.zoom > 0 &&
      call.point?.[0] === 83 &&
      call.point?.[1] === 61 &&
      call.sourceEvent === event,
  };
};

export const mkSyncSpy = () => {
  const selection = { property: (name) => name === "__zoom" ? { x: 1, y: 2, k: 3 } : null };
  const calls = [];
  const behavior = {
    transform(actualSelection, transform, point, sourceEvent) {
      calls.push({ actualSelection, transform, point, sourceEvent });
    },
  };
  return {
    behavior,
    selection,
    sawNoCalls: () => calls.length === 0,
    sawExpectedCall: () =>
      calls.length === 1 &&
      calls[0].actualSelection === selection &&
      calls[0].transform.x === 4 &&
      calls[0].transform.y === 5 &&
      calls[0].transform.k === 2 &&
      calls[0].point === null &&
      calls[0].sourceEvent?.sync === true,
  };
};

export const mkZoomEvent = (sync) => ({
  transform: { x: 4, y: 5, k: 2 },
  sourceEvent: sync ? { sync: true } : null,
});
