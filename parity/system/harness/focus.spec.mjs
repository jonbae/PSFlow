// The public node's focus behavior, with native pointer/keyboard modality.
import {test, expect} from '@playwright/test';
import {readFileSync} from 'node:fs';
import {runScenario, defineScenario} from './scenario.mjs';
import {routeOf} from '../corpus/routes.mjs';
import {createPagePort} from './port.mjs';
const baseline = JSON.parse(readFileSync('xyflow/packages/react/package.json')).version;
for (const side of ['upstream', 'psflow']) {
  for (const modality of ['pointer', 'keyboard']) {
    test(`${side} only auto-pans an offscreen node on keyboard focus (${modality})`, async ({page}) => {
      const port = createPagePort(page);
      const mount = defineScenario({
        id:'live--offscreen-focus', route:routeOf('./flow/chrome-defaults.ts'),
        async run(a) {
          await a.click('.react-flow__controls-zoomin');
          await a.call('setViewport', [{x:-1000,y:-1000,zoom:1}, {duration:0}]);
        },
      });
      await runScenario(page,mount,{side,capture:1,baseline,port});
      const viewport=page.locator('.react-flow__viewport');
      const before=await viewport.getAttribute('style');
      if (modality==='keyboard') await port.keyboard('press','Shift');
      const selector='.react-flow__node[data-id="n1"]';
      await port.focus(selector);
      expect(await page.locator(selector).evaluate(el=>el.matches(':focus-visible'))).toBe(modality==='keyboard');
      await port.tick();
      const after=await viewport.getAttribute('style');
      if (modality==='keyboard') expect(after).not.toBe(before);
      else expect(after).toBe(before);
    });
  }
}
