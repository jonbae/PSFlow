export const mergeStyles = (base) => (override) => ({ ...base, ...override });

export const joinSpace = (xs) => xs.filter((s) => s !== "").join(" ");
