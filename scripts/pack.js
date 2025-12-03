const { spawnSync } = require('child_process');
const path = require('path');
const pkg = require('../package.json');

const outputPath = path.join('dist', `gma2workers_v${pkg.version}.lua`);

const result = spawnSync('npx', ['luapack', '--config', 'luapack.config.json', '--output', outputPath], {
    stdio: 'inherit',
    shell: process.platform === 'win32'
});

if (result.status !== 0) {
    process.exit(result.status || 1);
}
