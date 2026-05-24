// Browser entry point. Pulls in the compiled PureScript output of
// `Example.Main` and runs its `main` Effect on load. esbuild bundles
// this file along with `react`, `react-dom` (and transitively the PS
// runtime + ps-flow output) into `dist/example.js`.

import { main } from "../../../output/Example.Main/index.js";

main();
