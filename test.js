// Minimal smoke test: start server, hit /healthz and /, assert responses.
process.env.PORT = '3999';
require('./server');
const http = require('http');
const get = (p) => new Promise((ok, fail) =>
  http.get({ host: '127.0.0.1', port: 3999, path: p }, (r) => {
    let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => ok({ code: r.statusCode, body: b }));
  }).on('error', fail));
(async () => {
  const h = await get('/healthz');
  if (h.code !== 200 || h.body !== 'ok') throw new Error('healthz failed');
  const i = await get('/');
  if (i.code !== 200 || !i.body.includes('Hello CI/CD')) throw new Error('index failed');
  console.log('All tests passed');
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
