// Renders design/final/*.svg into every PNG the app needs, using a headless
// Chrome started with --remote-debugging-port=9333.
//   node render.mjs
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const app = join(here, '..');
const res = join(app, 'android/app/src/main/res');
const svg = (name) => readFileSync(join(here, 'final', name), 'utf8');

const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
const jobs = [];
for (const [d, k] of Object.entries(densities)) {
  jobs.push({ svg: 'full.svg', size: 48 * k, shape: 'rounded', out: `${res}/mipmap-${d}/ic_launcher.png` });
  jobs.push({ svg: 'foreground.svg', size: 108 * k, out: `${res}/mipmap-${d}/ic_launcher_foreground.png` });
  jobs.push({ svg: 'monochrome.svg', size: 108 * k, out: `${res}/mipmap-${d}/ic_launcher_monochrome.png` });
  jobs.push({ svg: 'status.svg', size: 24 * k, out: `${res}/drawable-${d}/ic_stat_notify.png` });
}
jobs.push(
  { svg: 'full.svg', size: 512, out: `${here}/final/play-store-512.png` },
  { svg: 'full.svg', size: 192, shape: 'rounded', out: `${app}/web/icons/Icon-192.png` },
  { svg: 'full.svg', size: 512, shape: 'rounded', out: `${app}/web/icons/Icon-512.png` },
  { svg: 'full.svg', size: 192, out: `${app}/web/icons/Icon-maskable-192.png` },
  { svg: 'full.svg', size: 512, out: `${app}/web/icons/Icon-maskable-512.png` },
  { svg: 'full.svg', size: 32, shape: 'rounded', out: `${app}/web/favicon.png` },
  { svg: 'full.svg', size: 192, shape: 'rounded', out: `${app}/assets/app_icon.png` },
);

const tabs = await (await fetch('http://127.0.0.1:9333/json')).json();
const ws = new WebSocket(tabs.find((t) => t.type === 'page').webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener('open', r));
let id = 0;
const pending = new Map();
ws.addEventListener('message', (e) => {
  const m = JSON.parse(e.data);
  pending.get(m.id)?.(m);
});
const send = (method, params = {}) =>
  new Promise((r) => {
    const i = ++id;
    pending.set(i, r);
    ws.send(JSON.stringify({ id: i, method, params }));
  });

await send('Emulation.setDeviceMetricsOverride', { width: 600, height: 600, deviceScaleFactor: 1, mobile: false });
await send('Emulation.setDefaultBackgroundColorOverride', { color: { r: 0, g: 0, b: 0, a: 0 } });
await send('Page.navigate', { url: 'about:blank' });
await new Promise((r) => setTimeout(r, 500));

for (const j of jobs) {
  const radius = j.shape === 'rounded' ? '22%' : '0';
  const html = `<div style="width:${j.size}px;height:${j.size}px;border-radius:${radius};overflow:hidden">${svg(j.svg)
    .replace('<svg ', `<svg width="${j.size}" height="${j.size}" style="display:block" `)}</div>`;
  await send('Runtime.evaluate', {
    expression: `document.body.style.margin='0';document.body.style.background='transparent';document.body.innerHTML=${JSON.stringify(html)};document.fonts.ready`,
    awaitPromise: true,
  });
  const shot = await send('Page.captureScreenshot', {
    format: 'png',
    clip: { x: 0, y: 0, width: j.size, height: j.size, scale: 1 },
  });
  mkdirSync(dirname(j.out), { recursive: true });
  writeFileSync(j.out, Buffer.from(shot.result.data, 'base64'));
}
console.log(`rendered ${jobs.length} images`);
ws.close();
process.exit(0);
