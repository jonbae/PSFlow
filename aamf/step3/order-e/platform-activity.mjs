// Diagnostic only: platform registration/delivery order around initial layout.
export const observePlatform = () => {
  globalThis.__psflowActivity = [];
  const log = event => globalThis.__psflowActivity.push({at:performance.now(),...event});
  const schedule = globalThis.setTimeout;
  const cancel = globalThis.clearTimeout;
  globalThis.setTimeout = function(callback, delay, ...args) {
    const id = schedule(function(...values) {log({type:'timer.fire',id});return Reflect.apply(callback,this,values);},delay,...args);
    log({type:'timer.schedule',id,delay,stack:new Error().stack?.split('\n').slice(2,5)});return id;
  };
  globalThis.clearTimeout = function(id){log({type:'timer.cancel',id});return cancel(id);};
  const Observer=globalThis.ResizeObserver;
  globalThis.ResizeObserver=class extends Observer {
    constructor(cb){super((entries,observer)=>{log({type:'resize.fire',targets:entries.map(e=>e.target.className)});cb(entries,observer);});}
    observe(target,...args){log({type:'resize.observe',target:target.className});return super.observe(target,...args);}
  };
};
