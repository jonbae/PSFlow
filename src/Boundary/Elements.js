// FFI for `Boundary.Elements`.
//
// One function. `nodeTypes` maps names to *consumer* components, so crossing
// it means putting a wrapper between PSFlow's renderer and the user's
// component — and React needs that wrapper to be a real component function,
// not a call. `react-basic`'s `reactComponent` builds one but lives in
// `Effect`, and the prop conversion that needs this is pure, so the two lines
// that make a component out of a render function live here instead.

export const mkNodeComponentWrapper = (render) => {
  const Wrapper = (props) => render(props);
  Wrapper.displayName = "PSFlowNodeBoundary";
  return Wrapper;
};
