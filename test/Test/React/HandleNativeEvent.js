// Stand-ins for React's synthetic events, shaped as React builds them: the
// fields React copies from the DOM event, and the DOM event itself on
// `nativeEvent`. A synthetic touch event, like a DOM one, has no `clientX`.
const mouse = (button) => {
  const nativeEvent = { type: "mousedown", clientX: 10, clientY: 20, button };
  return { type: "mousedown", clientX: 10, clientY: 20, button, nativeEvent };
};

export const mouseDown = mouse(0);
export const secondaryMouseDown = mouse(2);

const touchNative = { type: "touchstart", touches: [{ clientX: 10, clientY: 20 }] };
export const touchStart = { type: "touchstart", touches: touchNative.touches, nativeEvent: touchNative };

export const isNativeOf = (synthetic) => (event) => event === synthetic.nativeEvent;
