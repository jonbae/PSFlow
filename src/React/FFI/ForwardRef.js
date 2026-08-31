import * as React from "react";

export const forwardRefImpl = (name) => (renderFn) => {
  const fwd = React.forwardRef((props, ref) => renderFn(props)(ref));
  fwd.displayName = name;
  return fwd;
};

// The same call as above, and deliberately the same one line: the two
// PureScript signatures differ only in what they promise about the ref, and a
// second implementation would be a second thing to keep in step.
export const forwardNullableRefImpl = forwardRefImpl;

// `ref` last and on its own line: it must overwrite whatever the props record
// happened to carry under that name, because the caller's forwarded ref is the
// one React means.
export const elementWithNullableRef = (component) => (props) => (ref) =>
  React.createElement(component, { ...props, ref });
