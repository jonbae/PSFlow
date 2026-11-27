// Pointer and keyboard input for the browser case tables, dispatched as a
// browser delivers it, with a frame between steps so d3 and the drag
// handlers see each one.

export const center = (element) => {
  const box = element.getBoundingClientRect();
  return { x: box.left + box.width / 2, y: box.top + box.height / 2 };
};

export const mouse = (target, type, { x, y, button = 0, buttons, ...rest } = {}) =>
  target.dispatchEvent(
    new MouseEvent(type, {
      bubbles: true,
      cancelable: true,
      view: window,
      clientX: x,
      clientY: y,
      button,
      buttons: buttons ?? (type === 'mouseup' || type === 'click' ? 0 : 1 << button),
      ...rest,
    })
  );

export const keyboard = (type, key, code = key) =>
  (document.activeElement ?? document.body).dispatchEvent(
    new KeyboardEvent(type, { key, code, bubbles: true, cancelable: true })
  );

export const node = (container, id) => container.querySelector(`.react-flow__node[data-id="${id}"]`);
export const pane = (container) => container.querySelector('.react-flow__pane');
export const handle = (container, id, type) => node(container, id).querySelector(`.react-flow__handle.${type}`);

// A press, `steps` moves of `dx`, `dy` in all, and a release.
export async function drag(context, target, { dx = 40, dy = 30, steps = 4, from, modifiers = {} } = {}) {
  const start = from ?? center(target);
  mouse(target, 'mousedown', { ...start, ...modifiers });
  await context.frame();
  for (let i = 1; i <= steps; i++) {
    mouse(window, 'mousemove', { x: start.x + (dx * i) / steps, y: start.y + (dy * i) / steps, ...modifiers });
    await context.frame();
  }
  mouse(window, 'mouseup', { x: start.x + dx, y: start.y + dy, ...modifiers });
  await context.frame();
}

// A connection drag from a's source handle to b's target handle, released.
export async function connect(context, { steps = 4 } = {}) {
  const { container } = context;
  const source = handle(container, 'a', 'source');
  const from = center(source);
  const to = center(handle(container, 'b', 'target'));
  mouse(source, 'mousedown', from);
  await context.frame();
  for (let i = 1; i <= steps; i++) {
    mouse(document, 'mousemove', { x: from.x + ((to.x - from.x) * i) / steps, y: from.y + ((to.y - from.y) * i) / steps });
    await context.frame();
  }
  mouse(document, 'mouseup', to);
  await context.frame();
}

export const click = (target) => {
  const at = center(target);
  mouse(target, 'mousedown', at);
  mouse(target, 'mouseup', at);
  mouse(target, 'click', at);
};

export const pressKey = async (context, key, code = key) => {
  keyboard('keydown', key, code);
  await context.frame();
  keyboard('keyup', key, code);
  await context.frame();
};
