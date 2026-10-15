const http = require('http');

const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || 'v1';

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('ok');
    return;
  }
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`
    <html>
      <head><title>Hello CI/CD</title></head>
      <body style="font-family: sans-serif; text-align: center; padding-top: 80px;">
        <h1>🚀 Hello IM lexsy — ${VERSION}</h1>
        <p>Deployed to k3s by Jenkins</p>
        <p>Host: ${require('os').hostname()}</p>
      </body>
    </html>
  `);
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}, version ${VERSION}`);
});
