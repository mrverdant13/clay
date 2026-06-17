import * as esbuild from 'esbuild';
import { readdirSync, readFileSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');
const srcDir = join(extensionRoot, 'src');

const skipModules = new Set(['extension']);

function usesVscodeRuntime(source) {
  return /import\s+\*\s+as\s+vscode\s+from\s+['"]vscode['"]/.test(source)
    || /import\s+(?!type\s)\{[^}]+\}\s+from\s+['"]vscode['"]/.test(source);
}

const moduleNames = readdirSync(srcDir)
  .filter((entry) => entry.endsWith('.ts'))
  .map((entry) => basename(entry, '.ts'))
  .filter((name) => !skipModules.has(name))
  .sort();

for (const moduleName of moduleNames) {
  const sourcePath = join(srcDir, `${moduleName}.ts`);
  const source = readFileSync(sourcePath, 'utf8');
  const external = usesVscodeRuntime(source) ? ['vscode'] : [];
  const siblingModules = moduleNames.filter((name) => name !== moduleName);

  await esbuild.build({
    entryPoints: [sourcePath],
    bundle: true,
    outfile: join(extensionRoot, `test/out/${moduleName}.cjs`),
    format: 'cjs',
    platform: 'node',
    external,
    plugins: [
      {
        name: 'externalize-sibling-modules',
        setup(build) {
          for (const sibling of siblingModules) {
            build.onResolve(
              { filter: new RegExp(`^\\.\\/${sibling}$`) },
              () => ({
                path: `./${sibling}.cjs`,
                external: true,
              }),
            );
          }
        },
      },
    ],
  });
}
