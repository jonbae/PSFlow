// Consumer observations and inputs for Step 4, order 8. No expected answers,
// side detection or library internals: both bundles execute this same source.
import { useEffect, useLayoutEffect, useState } from 'react';
import { createPortal, flushSync } from 'react-dom';
import { Handle, Panel, Position, useConnection, useReactFlow, useStoreApi } from '@xyflow/react';
import { installObservationLog } from '../../../driver/observations.mjs';

export const record = (name: string, ...args: unknown[]) =>
  (window as any).__psflowCalls?.record(name, args);

export function styleWitness(spec: Record<string, string[]>) {
  return function StyleWitness() {
    useEffect(() => installObservationLog(window).registerQuery('getComputedStyle', () =>
      Object.fromEntries(Object.entries(spec).map(([selector, fields]) => [selector,
        [...document.querySelectorAll(selector)].map(el => {
          const style = getComputedStyle(el);
          return Object.fromEntries(fields.map(field => [field, style.getPropertyValue(field)]));
        }),
      ]))), []);
    return <NestedPanelWitness />;
  };
}

function NestedPanelWitness() {
  const [pane, setPane] = useState<Element | null>(null);
  useEffect(() => { setPane(document.querySelector('.react-flow__pane')); }, []);
  return pane ? createPortal(<Panel data-testid="nested-selection-panel">nested panel</Panel>, pane) : null;
}

export function ViewportQueries() {
  const flow = useReactFlow();
  useEffect(() => installObservationLog(window).registerQuery('screenToFlowPositionOptions', () => ({
    inherited: flow.screenToFlowPosition({ x: 137, y: 93 }),
    unsnapped: flow.screenToFlowPosition({ x: 137, y: 93 }, { snapToGrid: false }),
    custom: flow.screenToFlowPosition({ x: 137, y: 93 }, { snapToGrid: true, snapGrid: [17, 23] }),
  })), [flow]);
  return null;
}

export function ExpandParentWitness() {
  const flow = useReactFlow();
  useEffect(() => {
    const change = (event: KeyboardEvent) => {
      if (event.key === 'e') flow.updateNode('child', { expandParent: false });
    };
    window.addEventListener('keydown', change);
    return () => window.removeEventListener('keydown', change);
  }, [flow]);
  return null;
}

export function StoreTimingWitness({ changed }: { changed: boolean }) {
  const store = useStoreApi();
  const read = () => {
    const s = store.getState();
    return { changed, minZoom: s.minZoom, nodes: s.nodes.map(n => n.id), ariaLabelConfig: s.ariaLabelConfig };
  };
  useLayoutEffect(() => { record('consumerLayoutEffect', read()); }, [changed]);
  useEffect(() => { record('consumerEffect', read()); }, [changed]);
  useEffect(() => installObservationLog(window).registerQuery('ariaLabelConfig', () => store.getState().ariaLabelConfig), [store]);
  return null;
}

// This reader lives inside GraphView's subtree, as the upstream #5733
// regression does. A sibling after StoreUpdater cannot observe its ordering
// relative to GraphView on a persistent-provider remount.
export function StoreReaderNode({ id, data }: any) {
  const store = useStoreApi();
  const read = () => {
    const s = store.getState();
    return { id, nodes: s.nodes.map(n => n.id), lookupSize: s.nodeLookup.size };
  };
  useLayoutEffect(() => { record('nodeConsumerLayoutEffect', read()); }, []);
  useEffect(() => { record('nodeConsumerEffect', read()); }, []);
  return <div style={{ width: 120, height: 40 }}>
    <Handle type="target" position={Position.Top} />{data.label}<Handle type="source" position={Position.Bottom} />
  </div>;
}

export function ScrollWitness() {
  useEffect(() => installObservationLog(window).registerQuery('wrapperScroll', () => {
    const el = document.querySelector('.react-flow')!;
    return { top: el.scrollTop, left: el.scrollLeft };
  }), []);
  return null;
}

export function StoreStateWitness() {
  const store = useStoreApi();
  useEffect(() => installObservationLog(window).registerQuery('storeState', () => {
    const s = store.getState();
    return { width: s.width, height: s.height, nodesSelectionActive: s.nodesSelectionActive,
      userSelectionActive: s.userSelectionActive, fitViewQueued: s.fitViewQueued,
      nodeIds: [...s.nodeLookup.keys()] };
  }), [store]);
  return <KeyboardWitness />;
}

export function KeyboardWitness() {
  useEffect(() => {
    const read = (event: KeyboardEvent) => {
      if (event.key.startsWith('Arrow')) record('consumerKey', { key: event.key, defaultPrevented: event.defaultPrevented });
    };
    window.addEventListener('keydown', read);
    return () => window.removeEventListener('keydown', read);
  }, []);
  return null;
}

export function WheelWitness() {
  useEffect(() => {
    const read = (event: WheelEvent) => record('consumerWheel', { ctrlKey: event.ctrlKey, defaultPrevented: event.defaultPrevented });
    window.addEventListener('wheel', read);
    return () => window.removeEventListener('wheel', read);
  }, []);
  return null;
}

export function DetachedNode({ data }: any) {
  return <div style={{ width: 120, height: 60 }}>
    <Handle id="in" type="target" position={Position.Top} isConnectableStart={false} />
    {data.label}
    <Handle id="out" type="source" position={Position.Bottom}>
      <span data-detached-hit={data.label} style={{ position: 'absolute', left: 15, top: 0, width: 25, height: 20, background: '#bbb' }} />
    </Handle>
  </div>;
}

export function ConnectionWitness() {
  const store = useStoreApi();
  const connection = useConnection();
  useEffect(() => {
    const change = (event: KeyboardEvent) => {
      if (event.key !== 'v' && event.key !== 't') return;
      const valid = event.key === 't';
      store.setState({
        isValidConnection: () => { record('currentIsValidConnection', valid); return valid; },
        onConnectEnd: (...args: unknown[]) => record('currentOnConnectEnd', valid, ...args),
      });
    };
    window.addEventListener('keydown', change);
    return () => window.removeEventListener('keydown', change);
  }, [store]);
  return <output data-connection-state={JSON.stringify({
    inProgress: connection.inProgress, from: connection.from, to: connection.to,
    pointer: connection.pointer, fromId: connection.fromNode?.id,
  })} style={{ display: 'none' }} />;
}

export function MissingMiniMapNodeWitness() {
  const store = useStoreApi();
  useEffect(() => {
    const change = (event: KeyboardEvent) => {
      if (event.key !== 'm') return;
      const original = store.getState().nodeLookup;
      const nodeLookup = new Map(original);
      nodeLookup.delete('Node-1');
      // Flush the missing-node render, then restore before the one settled
      // snapshot. A selector that dereferences the missing entry throws here.
      flushSync(() => store.setState({ nodeLookup }));
      flushSync(() => store.setState({ nodeLookup: original }));
    };
    window.addEventListener('keydown', change);
    return () => window.removeEventListener('keydown', change);
  }, [store]);
  return null;
}
