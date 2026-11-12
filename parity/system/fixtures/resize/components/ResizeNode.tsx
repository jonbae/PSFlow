// Consumer UI, shared unchanged by both libraries. Like PropsRecordNode this
// renders what public callbacks deliver, so the ordinary DOM trace observes it.
import { useEffect, useMemo, useState } from 'react';
import { NodeResizer, NodeResizeControl } from '@xyflow/react';

export default function ResizeNode() {
  const [history, setHistory] = useState<unknown[]>([]);
  const [maxWidth, setMaxWidth] = useState(500);
  const callbacks = useMemo(() => {
    const record = (name: string) => (_event: unknown, values: unknown) => {
      const snapshot = JSON.parse(JSON.stringify(values));
      setHistory(previous => [...previous, { name, values: snapshot }]);
    };
    return {
      resizer: { onResizeStart: record('resizer:start'), onResize: record('resizer:resize'), onResizeEnd: record('resizer:end') },
      control: { onResizeStart: record('control:start'), onResize: record('control:resize'), onResizeEnd: record('control:end') },
    };
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
