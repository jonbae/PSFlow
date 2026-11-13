import original from './selection-state';
export default { ...original, flowProps: { ...original.flowProps, selectionOnDrag: true, panOnDrag: [1, 2] } };
