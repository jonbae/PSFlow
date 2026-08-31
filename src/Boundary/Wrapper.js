// FFI for `Boundary.Wrapper`. One function, shared by the three props whose
// values are components the consumer wrote.
//
// The wrapper carries the wrapped component's own name. React devtools, error
// boundaries and every stack trace read `displayName` off the outermost
// function, so a fixed name here would rename every custom node type, every
// custom edge type and the minimap's node component to the same thing.
//
// The fallback is generic for the same reason the type is: this function
// cannot tell which of the three props it is serving, and inventing a name
// that says would mean three copies of it.

export const mkComponentWrapper = (wrapped) => (render) => {
  const Wrapper = (props) => render(props);
  Wrapper.displayName = wrapped.displayName || wrapped.name || "PSFlowUserComponent";
  return Wrapper;
};
