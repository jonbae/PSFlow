// External d3 selection seam: use the real behavior, capture its installed
// callbacks instead of requiring a browser DOM. Always restore the prototype.
import assert from 'node:assert/strict';
import * as d3Selection from 'd3-selection';
import * as d3Drag from 'd3-drag';
import { buildSync } from 'esbuild';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { newRenderer } from '../Test.React.Hook.OnInitTiming/foreign.js';
import { NodeResizeControl } from '../../index.js';
const { selection } = d3Selection;

const loadOracle = () => {
  const directory = mkdtempSync(join(tmpdir(), 'psflow-resize-oracle-'));
  const shim = join(directory, 'platform.mjs');
  writeFileSync(shim, [...Object.keys(d3Selection), ...Object.keys(d3Drag)].map(name => `export const ${name} = (...args) => globalThis.__psflowW05Platform.${name}(...args);`).join('\n'));
  try {
    const result = buildSync({ entryPoints:[fileURLToPath(new URL('../../xyflow/packages/system/src/xyresizer/XYResizer.ts',import.meta.url))], bundle:true,write:false,format:'cjs',platform:'node',logLevel:'silent',alias:{'d3-selection':shim,'d3-drag':shim} });
    const module = {exports:{}};
    new Function('module','exports',result.outputFiles[0].text)(module,module.exports);
    return module.exports.XYResizer;
  } finally { rmSync(directory,{recursive:true,force:true}); }
};

export const checkLifecycle = create => {
  const savedPlatform = globalThis.__psflowW05Platform;
  globalThis.__psflowW05Platform = {...d3Selection,...d3Drag};
  const original = selection.prototype.call;
  const behaviors = [];
  selection.prototype.call = function (behavior) { behaviors.push(behavior); return this; };
  try {
    const oracle = loadOracle();
    const calls = [];
    const node = { id: 'a', data: {}, position: { x: 30, y: 40 }, measured: { width: 100, height: 80 } };
    const instance = create({
      domNode: {}, nodeId: 'a',
      getStoreItems: () => ({ nodes: [node], transform: {x: 0, y: 0, scale: 1}, snapToGrid: false, nodeOrigin: [0,0] }),
      onChange: (change, children) => calls.push(['change', change, children]),
      onEnd: values => calls.push(['end', values]),
    });
    instance.update({
      controlPosition: 'bottom-right', boundaries: {minWidth:10,minHeight:10,maxWidth:500,maxHeight:500}, keepAspectRatio:false,
      onResizeStart: (event, values) => calls.push(['start', values]),
      onResize: (event, values) => calls.push(['resize', values]),
      onResizeEnd: (event, values) => calls.push(['resizeEnd', values]),
    });
    const behavior = behaviors.at(-1);
    const fire = (phase,x,y) => behavior.on(phase)({ sourceEvent: {clientX:x,clientY:y} });
    fire('start', 10, 20);
    assert.deepEqual(calls, [['start',{width:100,height:80,x:30,y:40}]]);
    fire('drag', 40, 40);
    fire('end', 40, 40);
    assert.deepEqual(calls, [
      ['start',{width:100,height:80,x:30,y:40}],
      ['resize',{width:130,height:100,x:30,y:40,direction:[1,1]}],
      ['change',{width:130,height:100},[]],
      ['resizeEnd',{width:130,height:100,x:30,y:40}],
      ['end',{width:130,height:100,x:30,y:40}],
    ]);
    instance.destroy();

    let comparisons = 0;
    const compare = (name, nodes, options, drive) => {
      comparisons++;
      const runs = [oracle, create].map((factory, index) => {
        const state = {nodes: structuredClone(nodes), transform: {x:0,y:0,scale:1}, snapToGrid:false,nodeOrigin:[0,0]};
        const receipts = [];
        const retainedChildren = [];
        const controller = factory({domNode:{},nodeId:'a',getStoreItems:()=> index === 1 ? state : ({...state,nodeLookup:new Map(state.nodes.map(n=>[n.id,n])),transform:[state.transform.x,state.transform.y,state.transform.scale]}),
          onChange:(change, children)=>{ retainedChildren.push(children); receipts.push(['change',structuredClone(change),structuredClone(children.map(({id,position})=>({id,position})))]); },
          onEnd:values=>receipts.push(['end',structuredClone(values)]),
        });
        const update = (overrides={}) => {
          controller.update({controlPosition:'bottom-right',boundaries:{minWidth:10,minHeight:10,maxWidth:500,maxHeight:500},keepAspectRatio:false,
            onResizeStart:(event,values)=>receipts.push(['start',structuredClone(values)]),
            onResize:(event,values)=>receipts.push(['resize',structuredClone(values)]),
            onResizeEnd:(event,values)=>receipts.push(['resizeEnd',structuredClone(values)]),
            ...(typeof options === 'function' ? options(receipts) : options),...overrides});
          return behaviors.at(-1);
        };
        const behavior = update();
        const fire = (phase,x,y,b=behavior) => b.on(phase)({sourceEvent:{clientX:x,clientY:y}});
        drive({fire,update,state,receipts,retainedChildren});
        controller.destroy();
        return receipts;
      });
      assert.deepEqual(runs[1],runs[0],name);
    };
    compare('top-left child position correction preserves insertion order',[
      {id:'z-child',parentId:'a',position:{x:12,y:8},measured:{width:15,height:10},data:{}},
      node,
      {id:'b-child',parentId:'a',position:{x:40,y:20},measured:{width:10,height:12},data:{}},
    ],{controlPosition:'top-left'},({fire})=>{fire('start',10,20);fire('drag',-10,0);fire('drag',-20,-10);fire('end',-20,-10);});
    compare('expandParent corrects previous and start positions before notifications',[
      {id:'p',position:{x:0,y:0},measured:{width:200,height:200},data:{}},
      {...node,parentId:'p',expandParent:true,position:{x:10,y:20}},
    ],{controlPosition:'top-left'},({fire})=>{fire('start',10,20);fire('drag',-20,-20);fire('drag',-30,-30);fire('end',-30,-30);});

    const gesture = ({fire}) => { fire('start',10,20); fire('drag',45,60); fire('drag',-30,-20); fire('end',-30,-20); fire('end',-30,-20); };
    for (const controlPosition of ['top','bottom','left','right','top-left','top-right','bottom-left','bottom-right']) {
      for (const keepAspectRatio of [false,true]) {
        for (const resizeDirection of [undefined,'horizontal','vertical']) {
          compare(`constraints ${controlPosition} aspect=${keepAspectRatio} direction=${resizeDirection}`,[{...node,origin:[0.5,1]}],
            {controlPosition,keepAspectRatio,resizeDirection,boundaries:{minWidth:70,minHeight:50,maxWidth:150,maxHeight:110}},gesture);
        }
      }
    }
    compare('a coordinate extent constrains resizing',[{...node,position:{x:40,y:30},extent:[[0,0],[160,130]]}],{},gesture);
    compare('a parent extent uses measured parent dimensions',[
      {id:'p',position:{x:10,y:20},measured:{width:160,height:130},data:{}},
      {...node,parentId:'p',position:{x:40,y:30},extent:'parent'},
    ],{},gesture);
    compare('child extent and child origin constrain parent shrink',[
      node,{id:'z-child',parentId:'a',position:{x:75,y:50},measured:{width:30,height:20},origin:[0.5,1],extent:'parent',data:{}},
    ],{},gesture);
    compare('fractional child extent preserves source arithmetic order',[
      {...node,position:{x:1,y:0},measured:{width:1,height:1}},
      {id:'z-child',parentId:'a',position:{x:0.1,y:0.2},measured:{width:0.1,height:0.2},origin:[0.5,0.5],extent:'parent',data:{}},
    ],{controlPosition:'right',boundaries:{minWidth:0,minHeight:0,maxWidth:500,maxHeight:500}},({fire})=>{fire('start',0,0);fire('drag',-1,0);fire('end',-1,0);});
    compare('no node produces no lifecycle',[],{},gesture);
    compare('a no-op drag produces no resize or end',[node],{},({fire})=>{fire('start',10,20);fire('drag',10,20);fire('end',10,20);});
    compare('vetoed resizes still advance previous values',[node],receipts=>({shouldResize:(_event,values)=>{
      receipts.push(['shouldResize',structuredClone(values)]);return values.width >= 130;
    }}),({fire})=>{fire('start',10,20);fire('drag',20,30);fire('drag',45,60);fire('drag',30,35);fire('end',30,35);});
    compare('a completely vetoed gesture emits no end',[node],{shouldResize:()=>false},gesture);
    compare('resize detection does not depend on an onResize callback',[node],{onResize:undefined},gesture);
    compare('a later gesture starts again from the store',[node],{},({fire,state})=>{
      gesture({fire});state.nodes[0].measured={width:140,height:90};state.nodes[0].position={x:50,y:60};gesture({fire});
    });
    compare('live transform, grid and store origin are read on each tick',[node],{},({fire,state})=>{
      fire('start',10,20);state.transform={x:5,y:10,scale:2};state.snapToGrid=true;state.snapGrid=[10,10];state.nodeOrigin=[0.5,1];fire('drag',65,90);fire('end',65,90);
    });
    compare('container bounds are captured at the start',[node],{},({fire,state})=>{
      let left=10;state.paneDomNode={getBoundingClientRect:()=>({left,top:20,width:500,height:400})};fire('start',20,40);left=200;fire('drag',50,60);fire('end',50,60);
    });
    compare('an active gesture keeps its callbacks and reads later geometry options',[node],{},({fire,update,receipts})=>{
      fire('start',10,20);fire('drag',20,30);
      const replacement=update({boundaries:{minWidth:10,minHeight:10,maxWidth:125,maxHeight:95},onResize:(_event,values)=>receipts.push(['replacementResize',structuredClone(values)])});
      fire('drag',70,90);fire('end',70,90);
      // The replacement update has its own unstarted state, not the old drag.
      fire('drag',80,100,replacement);
      fire('start',10,20,replacement);fire('drag',70,90,replacement);fire('end',70,90,replacement);
    });
    compare('child objects are retained while each emitted array is fresh',[
      node,{id:'z-child',parentId:'a',position:{x:12,y:8},measured:{width:10,height:10},data:{}},
    ],{controlPosition:'top-left'},({fire,retainedChildren})=>{
      fire('start',10,20);fire('drag',0,10);const first=retainedChildren[0];fire('drag',-10,0);
      assert.notEqual(retainedChildren[1],first);assert.equal(retainedChildren[1][0],first[0]);
      assert.deepEqual(first[0].position,{x:32,y:28});fire('end',-10,0);
    });
    compare('predicate and notification receive the same consumer payload',[node],receipts=>{
      let offered;
      return {shouldResize:(_event,values)=>{offered=values;values.width=321;values.custom='kept';return true;},
        onResize:(_event,values)=>{assert.equal(values,offered);receipts.push(['resize',structuredClone(values)]);}};
    },gesture);
    console.log(`XYResizer: basic lifecycle and ${comparisons} source-differential cases passed`);

  } finally { selection.prototype.call = original; if(savedPlatform === undefined) delete globalThis.__psflowW05Platform; else globalThis.__psflowW05Platform=savedPlatform; }
};

// Independent expectations are executed from the pinned vendored TS, with only
// external d3/DOM operations supplied by the same native platform seam.

export const controlNode = {id:'a',position:{x:30,y:40},measured:{width:120,height:80},data:{}};
export const checkControl = (context, setScale) => {
  const original = selection.prototype.call;
  const behaviors = [];
  const dom = {removeEventListener(){}};
  selection.prototype.call = function (behavior) {
    behaviors.push(behavior);
    dom.__on=[{type:'mousedown',name:'drag',listener(){},options:undefined}];
    return this;
  };
  const renderer = newRenderer(context)();
  try {
    const calls = [];
    const props = {nodeId:'a',position:'bottom-right',minWidth:40,minHeight:30,maxWidth:500,
      onResizeStart:(_event,values)=>calls.push(['start',values]),
      onResize:(_event,values)=>calls.push(['resize',values]),
      onResizeEnd:(_event,values)=>calls.push(['end',values]),
    };
    const render = options => {
      let rendered;
      renderer.render(()=>{
      let element = NodeResizeControl.type(options);
      while(typeof element.type !== 'string') {
        const component = typeof element.type === 'function' ? element.type : element.type.type;
        element = component(element.props);
      }
      element.ref.current = dom;
      rendered=element;
      });
      return rendered;
    };
    setScale(0.5);
    assert.equal(render(props).props.style.scale,'2','zoomed-out handles retain their screen size');
    const active = behaviors[0];
    const fire = (phase,x,y) => active.on(phase)({sourceEvent:{clientX:x,clientY:y}});
    fire('start',10,20);fire('drag',25,30);
    render({...props,maxWidth:145});
    fire('drag',70,50);fire('end',70,50);
    assert.equal(calls.at(-1)[1].width,145,'mounted control keeps its controller when props change during a drag');
    const count = behaviors.length;
    render({...props,maxWidth:145});
    assert.equal(behaviors.length,count,'unchanged callback payloads and props do not reinstall d3');
    render({...props,maxWidth:145,resizeDirection:'horizontal'});
    assert.equal(behaviors.length,count,'source update dependencies do not include resizeDirection');
    assert.equal(render({...props,maxWidth:145,autoScale:false}).props.style.scale,undefined);
    setScale(2);
    assert.equal(render({...props,maxWidth:145}).props.style.scale,'1','zooming in does not shrink controls');
    renderer.unmount();
    assert.equal(dom.__on,undefined,'unmount removes the drag binding');
  } finally { selection.prototype.call = original; }
};

export const checkParentControl = createContext => {
  const original = selection.prototype.call;
  let behavior;
  selection.prototype.call = function (value) { behavior=value; return this; };
  try {
    const changes=[];
    const context=createContext([
      {id:'p',position:{x:0,y:0},measured:{width:300,height:200},data:{}},
      {...controlNode,parentId:'p',expandParent:true,position:{x:10,y:20}},
    ],values=>changes.push(...values));
    const renderer=newRenderer(context)();
    renderer.render(()=>{
      const boundary=NodeResizeControl.type({nodeId:'a',position:'top-left',minWidth:40,minHeight:30});
      const element=boundary.type.type(boundary.props);
      element.ref.current={};
    });
    behavior.on('start')({sourceEvent:{clientX:10,clientY:20}});
    behavior.on('drag')({sourceEvent:{clientX:0,clientY:0}});
    assert.ok(changes.some(c=>c.type==='dimensions'&&c.id==='a'));
    assert.equal(changes.some(c=>c.type==='position'&&c.id==='a'),false,'expandParent omits a zero corrected position as source does');
    behavior.on('end')({sourceEvent:{clientX:0,clientY:0}});
    assert.equal(changes.at(-1).type,'dimensions');
    assert.equal(changes.at(-1).resizing,false);
    assert.deepEqual(changes.at(-1).dimensions,{width:130,height:100},'final resize changes retain final dimensions');
    changes.length=0;
    behavior.on('start')({sourceEvent:{clientX:10,clientY:20}});
    behavior.on('drag')({sourceEvent:{clientX:NaN,clientY:NaN}});
    assert.equal(changes.some(c=>c.type==='position'&&c.id==='a'),false,'expandParent treats NaN positions as falsy');
    renderer.unmount();
  } finally { selection.prototype.call=original; }
};
