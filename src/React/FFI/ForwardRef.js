import * as React from "react";

export const forwardNullableRefImpl = (name) => (renderFn) => {
  const fwd = React.forwardRef((props, ref) => renderFn(props)(ref));
  fwd.displayName = name;
  return fwd;
};
