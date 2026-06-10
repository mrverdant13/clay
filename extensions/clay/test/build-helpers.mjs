import * as esbuild from 'esbuild';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');

await esbuild.build({
  entryPoints: [join(extensionRoot, 'src/annotationBlockPairing.ts')],
  bundle: true,
  outfile: join(extensionRoot, 'test/out/annotationBlockPairing.cjs'),
  format: 'cjs',
  platform: 'node',
  external: [],
});

await esbuild.build({
  entryPoints: [join(extensionRoot, 'src/annotationMarkerSets.ts')],
  bundle: true,
  outfile: join(extensionRoot, 'test/out/annotationMarkerSets.cjs'),
  format: 'cjs',
  platform: 'node',
  external: [],
});

await esbuild.build({
  entryPoints: [join(extensionRoot, 'src/brickGen.ts')],
  bundle: true,
  outfile: join(extensionRoot, 'test/out/brickGen.cjs'),
  format: 'cjs',
  platform: 'node',
  external: [],
});

await esbuild.build({
  entryPoints: [join(extensionRoot, 'src/brickScope.ts')],
  bundle: true,
  outfile: join(extensionRoot, 'test/out/brickScope.cjs'),
  format: 'cjs',
  platform: 'node',
  external: [],
});

await esbuild.build({
  entryPoints: [join(extensionRoot, 'src/workspaceClayScript.ts')],
  bundle: true,
  outfile: join(extensionRoot, 'test/out/workspaceClayScript.cjs'),
  format: 'cjs',
  platform: 'node',
  external: [],
});

await esbuild.build({
  entryPoints: [join(extensionRoot, 'src/previewRunner.ts')],
  bundle: true,
  outfile: join(extensionRoot, 'test/out/previewRunner.cjs'),
  format: 'cjs',
  platform: 'node',
  external: [],
});

await esbuild.build({
  entryPoints: [join(extensionRoot, 'src/brickVariables.ts')],
  bundle: true,
  outfile: join(extensionRoot, 'test/out/brickVariables.cjs'),
  format: 'cjs',
  platform: 'node',
  external: [],
});

await esbuild.build({
  entryPoints: [join(extensionRoot, 'src/previewFileVariables.ts')],
  bundle: true,
  outfile: join(extensionRoot, 'test/out/previewFileVariables.cjs'),
  format: 'cjs',
  platform: 'node',
  external: [],
});

await esbuild.build({
  entryPoints: [join(extensionRoot, 'src/previewVariableState.ts')],
  bundle: true,
  outfile: join(extensionRoot, 'test/out/previewVariableState.cjs'),
  format: 'cjs',
  platform: 'node',
  external: [],
});
