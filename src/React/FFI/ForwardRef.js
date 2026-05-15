import * as React from "react";

export const forwardRefImpl = (name) => (renderFn) => {
  const fwd = React.forwardRef((props, ref) => renderFn(props)(ref));
  fwd.displayName = name;
  return fwd;
};
