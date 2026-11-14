// Optional platform API; the visibility decision and resize behavior live in
// PureScript. Older browsers without checkVisibility are treated as visible.
export const checkVisibility = element => element.checkVisibility?.() ?? true;
