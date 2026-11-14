import original from './nowheel';
export default { ...original, flowProps: { ...original.flowProps, panOnScroll: true, zoomActivationKeyCode: 'z' } };
