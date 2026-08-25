// FFI for `Boundary.Promise`. One thing lives here: the constructor.
//
// `new Promise` is not expressible in PureScript, and the executor's
// `(resolve, reject)` is the shape `Effect.Aff.runAff_` wants to be handed
// anyway, so the bridge is a single line and the decision about *when* the
// `Aff` starts lives on the PureScript side where it can be read.
//
// `start` is an `EffectFn2`, so it is a plain two-argument JavaScript function
// here; `resolve` and `reject` are one-argument functions, which is what
// `EffectFn1 a Unit` compiles to. Nothing needs uncurrying by hand.

export const mkPromise = (start) => new Promise((resolve, reject) => start(resolve, reject));
