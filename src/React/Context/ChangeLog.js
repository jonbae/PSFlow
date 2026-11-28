// `console.log` with upstream's two arguments, for `React.Context.ChangeLog`.
export const logChanges = (message) => (changes) => () => console.log(message, changes);
