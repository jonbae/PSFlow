// The inputs surface parity calls upstream's edge-path helpers with, as a
// JavaScript caller writes them, and the same points with every option left
// out, so the converters have to supply upstream's defaults.
const edgePoints = { sourceX: 0, sourceY: 20, targetX: 150, targetY: 100 };

export const points = edgePoints;

export const bezierControl = {
  ...edgePoints,
  sourceControlX: 50,
  sourceControlY: 20,
  targetControlX: 100,
  targetControlY: 100,
};

export const bezierRightLeft = { ...edgePoints, sourcePosition: "right", targetPosition: "left", curvature: 0.25 };

export const bezierDefaults = { ...edgePoints, sourcePosition: "bottom", targetPosition: "top", curvature: 0.25 };

export const smoothStepRightLeft = {
  ...edgePoints,
  sourcePosition: "right",
  targetPosition: "left",
  borderRadius: 5,
  offset: 20,
  stepPosition: 0.5,
};

export const smoothStepDefaults = {
  ...edgePoints,
  sourcePosition: "bottom",
  targetPosition: "top",
  borderRadius: 5,
  offset: 20,
  stepPosition: 0.5,
};

export const json = (value) => JSON.stringify(value);

// A target above a bottom source, where the control points would point
// backwards. Upstream applies the curvature only there, so the points above
// never read it.
export const backwards = { sourceX: 0, sourceY: 100, targetX: 150, targetY: 20 };

export const backwardsDefaults = { ...backwards, sourcePosition: "bottom", targetPosition: "top", curvature: 0.25 };
