// Public instance reads over the actual store; independent source change helper.
import assert from 'node:assert/strict';
import { applyNodeChanges } from '@xyflow/react';
export { renderWithStore } from '../Test.Boundary.UserNode/foreign.js';

export const checkResizing = create => {
  for(const flag of [undefined,false,true]) {
    let expected=[{id:'resize',position:{x:0,y:0},data:{},...(flag===undefined?{}:{resizing:flag})}];
    const session=create(expected[0]);
    const check = () => {
      const result=session.read();
      for(const node of [result.nodes[0],result.internal]){
        assert.equal(Object.hasOwn(node,'resizing'),Object.hasOwn(expected[0],'resizing'));
        assert.equal(node.resizing,expected[0].resizing);
      }
    };
    check();
    for(const change of [
      {type:'dimensions',id:'resize',dimensions:{width:140,height:100},resizing:true},
      {type:'dimensions',id:'resize',dimensions:{width:150,height:110}},
      {type:'dimensions',id:'resize',resizing:false},
      {type:'dimensions',id:'resize',resizing:true},
    ]){expected=applyNodeChanges([change],expected);session.change(change);check();}
  }
};
