// FFI for the ColorMode example page (ticket 065). `select`/`option` aren't in
// `React.FFI.DOM`, and we need a change handler that reads `event.target.value`.
import * as React from "react";

const mk = (tag) => (props) => (children) =>
  React.createElement(tag, props, ...children);

export const select_ = mk("select");
export const option_ = mk("option");

// `EventHandler` (react-basic) is `EffectFn1 SyntheticEvent Unit` → `(event) => …`.
// `cb :: String -> Effect Unit` is `(str) => (() => …)`, so run `cb(value)()`.
export const onSelectChangeImpl = (cb) => (event) => {
  cb(event.target.value)();
};
