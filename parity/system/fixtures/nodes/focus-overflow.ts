import { ScrollWitness, record } from '../shared/DebtWitnesses';
export default {
  flowProps: {
    autoPanOnNodeFocus: false,
    nodes: [
      { id: 'near', position: { x: 10, y: 10 }, data: { label: 'near' } },
      { id: 'far', position: { x: 1800, y: 1200 }, data: { label: 'far' } },
    ], edges: [],
    onScroll: (event: any) => record('wrapperScroll', event.currentTarget.scrollTop, event.currentTarget.scrollLeft),
  },
  witness: ScrollWitness,
};
