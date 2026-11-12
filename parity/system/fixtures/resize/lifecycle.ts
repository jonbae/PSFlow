// Real resize controls and consumer-rendered lifecycle receipts. Geometry starts
// measured and without fitView so the gesture is independent of mount animation.
import ResizeNode from './components/ResizeNode';

export default {
  flowProps: {
    nodeTypes: { resizeReceipt: ResizeNode },
    nodes: [{
      id: 'resize', type: 'resizeReceipt', data: {}, position: { x: 240, y: 180 },
      width: 120, height: 80, measured: { width: 120, height: 80 },
      style: { width: 120, height: 80 },
    }],
    edges: [],
  },
};
