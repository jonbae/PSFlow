// PSFlow-specific NodeProps guard, now mounted through the JS surface. The
// custom component deliberately renders the values it receives so the browser
// spec can distinguish absolute from relative position and explicit flags from
// flow-level defaults.
import { ReactFlow } from '@xyflow/react';

function NodePropsNode(props: any) {
  return (
    <div
      className="node-props-node"
      style={{
        width: props.width == null ? '100px' : `${props.width}px`,
        height: props.height == null ? '40px' : `${props.height}px`,
        border: '1px solid #222',
        background: '#eee',
        fontSize: '10px',
      }}
      data-selectable={String(props.selectable)}
      data-draggable={String(props.draggable)}
      data-deletable={String(props.deletable)}
      data-width={props.width ?? ''}
      data-height={props.height ?? ''}
      data-parent-id={props.parentId ?? ''}
      data-pos-x={props.positionAbsoluteX}
      data-pos-y={props.positionAbsoluteY}
    >
      {props.id}
    </div>
  );
}

const nodes = [
  {
    id: 'probe-parent',
    type: 'NodePropsNode',
    position: { x: 100, y: 200 },
    data: {},
    width: 300,
    height: 200,
    measured: { width: 300, height: 200 },
  },
  {
    id: 'probe-child',
    type: 'NodePropsNode',
    position: { x: 50, y: 25 },
    data: {},
    parentId: 'probe-parent',
    selectable: false,
    draggable: false,
    deletable: false,
    width: 120,
    height: 40,
    measured: { width: 120, height: 40 },
  },
];

const nodeTypes = { NodePropsNode };

export default function NodePropsGuard() {
  return (
    <div style={{ height: '100%' }}>
      <ReactFlow nodes={nodes} edges={[]} nodeTypes={nodeTypes} fitView />
    </div>
  );
}
