// A flow taller than the window, so the page itself can scroll (#4862, #4991).
//
// Both rows are about a browser default around **focus and arrow keys**: one
// that an arrow key moving a node must not also scroll the page, the other that
// focusing a node must not make the browser scroll the flow into view and shift
// the viewport. Neither is observable on a page that cannot scroll — both sides
// record a scroll offset of zero and agree about nothing.
//
// So the flow is given a height past the 720px viewport the net runs in, which
// puts a scrollbar on the document and makes `dom.page.scrollX`/`scrollY` a
// live measurement rather than a constant. That is the page-level state ticket
// 080 enumerated for exactly these two rows.
//
// `fitView` is off and the viewport is fixed: a fit against a container this
// tall would set a zoom neither row is about, and the nodes need to be spread
// down the page for a focus to have somewhere to scroll to.

export default {
  flowProps: {
    style: { height: '1600px' },
    defaultViewport: { x: 0, y: 0, zoom: 1 },
    nodeDragThreshold: 0,
    nodes: [
      { id: 'Node-1', data: { label: 'Node-1' }, position: { x: 0, y: 0 }, type: 'input' },
      { id: 'Node-2', data: { label: 'Node-2' }, position: { x: 0, y: 400 } },
      { id: 'Node-3', data: { label: 'Node-3' }, position: { x: 0, y: 800 } },
      { id: 'Node-4', data: { label: 'Node-4' }, position: { x: 0, y: 1200 }, type: 'output' },
    ],
    edges: [
      { id: '1-2', source: 'Node-1', target: 'Node-2' },
      { id: '2-3', source: 'Node-2', target: 'Node-3' },
      { id: '3-4', source: 'Node-3', target: 'Node-4' },
    ],
  },
};
