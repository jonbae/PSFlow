// Native property presence and writes for pointer narrowing and owned resize records.
export const hasProperty = (key, object) => key in object;
export const writeProperty = (key, object, value) => { object[key] = value; };
