// Consumer UI, shared unchanged by both libraries. Like PropsRecordNode this
// renders what public callbacks deliver, so the ordinary DOM trace observes it.
//
// The handlers are also recorded into the net's call log under upstream's prop
// names, `onResizeStart`, `onResize`, `onResizeEnd` and `shouldResize`. They
// are props of the two resize components rather than of `<ReactFlow />`, so
// the driver installs none of them, and the `callbacks` section sees them only
// if the consumer that passes them records them. `shouldResize` answers true,
// which resizes exactly as leaving it out does.
import { useEffect, useMemo, useState } from 'react';
import { NodeResizer, NodeResizeControl } from '@xyflow/react';

type Handler = (...args: unknown[]) => unknown;
type CallLog = { wrap: (name: string, handler: Handler) => Handler };

const observed = (name: string, handler: Handler): Handler => {
  const log = (window as unknown as { __psflowCalls?: CallLog }).__psflowCalls;
  return log ? log.wrap(name, handler) : handler;
};

export default function ResizeNode() {
  const [history, setHistory] = useState<unknown[]>([]);
  const [maxWidth, setMaxWidth] = useState(500);
  const callbacks = useMemo(() => {
    const record = (name: string) => (_event: unknown, values: unknown) => {
      const snapshot = JSON.parse(JSON.stringify(values));
      setHistory(previous => [...previous, { name, values: snapshot }]);
    };
    const handlers = (prefix: string) => ({
      onResizeStart: observed('onResizeStart', record(`${prefix}:start`)),
      onResize: observed('onResize', record(`${prefix}:resize`)),
      onResizeEnd: observed('onResizeEnd', record(`${prefix}:end`)),
      shouldResize: observed('shouldResize', () => true),
    });
    return { resizer: handlers('resizer'), control: handlers('control') };
  }, []);
  useEffect(() => {
    const update = (event: KeyboardEvent) => { if (event.key === 'l') setMaxWidth(145); };
    window.addEventListener('keydown', update);
    return () => window.removeEventListener('keydown', update);
  }, []);
  return (
    <div style={{ width: '100%', height: '100%', background: '#eee', border: '1px solid #222', boxSizing: 'border-box' }}
      data-resize-history={JSON.stringify(history)} data-resize-max-width={maxWidth}>
      <NodeResizer minWidth={40} minHeight={30} maxWidth={maxWidth} {...callbacks.resizer} />
      <NodeResizeControl className="resize-direct" position="bottom-right" minWidth={40} minHeight={30} maxWidth={maxWidth} {...callbacks.control} />
      Resize
    </div>
  );
}
