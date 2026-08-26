// FFI for `Boundary.FitView`. Two type tests upstream makes inline and
// PureScript cannot express, both about `padding`.
//
//   * `describe` — `String(value)`, which is what upstream's error message
//     interpolates. Going through `String` rather than building the text in
//     PureScript is the whole point: an object has to print `[object Object]`
//     and a boolean `true`, or the two console lines differ on the one run
//     where a consumer got this wrong, which is the run that matters.
//
//   * `isObject` — upstream's second branch is a bare `typeof === 'object'`,
//     which admits `null`. Ours excludes it: `null` cannot reach here, because
//     `Boundary.Undefined` reads it as an absent option one level up, and a
//     guard that can only fire on an unreachable value is a guard nobody can
//     check. Excluding it says so.

export const describe = (value) => String(value);

export const isObject = (value) => typeof value === "object" && value !== null;
