// FFI for `Boundary.Elements`.
//
// One function. `nodeTypes` maps names to *consumer* components, so crossing
// it means putting a wrapper between PSFlow's renderer and the user's
// component — and React needs that wrapper to be a real component function,
// not a call. `react-basic`'s `reactComponent` builds one but lives in
// `Effect`, and the prop conversion that needs this is pure, so the two lines
// that make a component out of a render function live here instead.
//
// The wrapper carries the wrapped component's own name. React devtools, error
// boundaries and every stack trace read `displayName` off the outermost
// function, so a fixed name here would rename every custom node type in the
// tree to the same thing.

export const mkNodeComponentWrapper = (wrapped) => (render) => {
  const Wrapper = (props) => render(props);
  Wrapper.displayName = wrapped.displayName || wrapped.name || "PSFlowNodeType";
  return Wrapper;
};
