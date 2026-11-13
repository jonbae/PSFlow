// Every built-in edge type a consumer can declare, and one of the consumer's
// own registered under `custom`.
//
// The corpus draws every other edge as the default bezier, so the four other
// built-in components, and their props, are mounted by nothing else. The custom
// type is registered under the key the `EdgeTypes` witness names, and it mounts
// `EdgeLabelRenderer`, `EdgeToolbar` and `ViewportPortal`; see
// `components/PortalEdge.tsx`.
//
// Each edge has a source and a target node of its own, so no two paths overlap
// and a click on the custom edge lands on that edge.

import PortalEdge from './components/PortalEdge';

const node = (id: string, x: number, y: number, type?: string) => ({
  id,
  data: { label: id },
  position: { x, y },
  ...(type ? { type } : {}),
});

export default {
  flowProps: {
    fitView: true,
    edgeTypes: { custom: PortalEdge },
    nodes: [
      node('simplebezier-source', 0, 0, 'input'),
      node('simplebezier-target', 0, 160, 'output'),
      node('smoothstep-source', 220, 0, 'input'),
      node('smoothstep-target', 320, 160, 'output'),
      node('step-source', 480, 0, 'input'),
      node('step-target', 580, 160, 'output'),
      node('straight-source', 740, 0, 'input'),
      node('straight-target', 740, 160, 'output'),
      node('custom-source', 960, 0, 'input'),
      node('custom-target', 1060, 200, 'output'),
    ],
    edges: [
      { id: 'simplebezier', type: 'simplebezier', source: 'simplebezier-source', target: 'simplebezier-target' },
      { id: 'smoothstep', type: 'smoothstep', source: 'smoothstep-source', target: 'smoothstep-target', label: 'smoothstep' },
      { id: 'step', type: 'step', source: 'step-source', target: 'step-target' },
      { id: 'straight', type: 'straight', source: 'straight-source', target: 'straight-target', label: 'straight' },
      { id: 'custom', type: 'custom', source: 'custom-source', target: 'custom-target', data: { label: 'custom' } },
    ],
  },
};
