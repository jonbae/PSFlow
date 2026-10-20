// What a JavaScript consumer reads off the connection state `onConnectEnd`
// receives.
export const toPositionIsNull = (state) => state.toPosition === null;

export const toPositionIs = (position) => (state) => state.toPosition === position;
