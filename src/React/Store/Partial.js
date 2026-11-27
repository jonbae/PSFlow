// zustand's merge, `Object.assign({}, state, partial)`, and the members a
// partial names, in its order.
export const assignImpl = (state) => (partial) => Object.assign({}, state, partial);

export const keysImpl = (partial) => Object.keys(partial);
