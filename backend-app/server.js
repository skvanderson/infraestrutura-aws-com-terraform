const http = require('http');

const PORT = 8080;

const server = http.createServer((req, res) => {
  const url = new URL(req.url || '/', `http://localhost:${PORT}`);
  res.setHeader('Content-Type', 'application/json; charset=utf-8');

  if (url.pathname === '/' || url.pathname === '/api') {
    res.writeHead(200);
    res.end(JSON.stringify({
      service: 'Portfolio Cloud Backend',
      version: '1.0',
      message: 'API de exemplo em container (ECS Fargate)',
      endpoints: {
        '/api': 'esta mensagem',
        '/api/health': 'status de saúde',
        '/api/echo?msg=texto': 'eco do parâmetro msg',
      },
      timestamp: new Date().toISOString(),
    }));
    return;
  }

  if (url.pathname === '/api/health') {
    res.writeHead(200);
    res.end(JSON.stringify({ status: 'ok', uptime: process.uptime() }));
    return;
  }

  if (url.pathname === '/api/echo') {
    const msg = url.searchParams.get('msg') || 'nenhuma mensagem';
    res.writeHead(200);
    res.end(JSON.stringify({ echo: msg, receivedAt: new Date().toISOString() }));
    return;
  }

  res.writeHead(404);
  res.end(JSON.stringify({ error: 'Not Found', path: url.pathname }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend rodando na porta ${PORT}`);
});
