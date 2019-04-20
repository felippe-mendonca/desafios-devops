const express = require('express')
const app = express()
const router = express.Router()
const port = 3000;

var isHealthy = true

app.listen(port);
console.log(`Aplicação teste executando em http://localhost: ${port}`);

router.get('/', (req, res) => {
  const name = process.env.NAME || 'candidato';
  res.send(`Olá ${name}!`);
});

router.get('/healthz', (req, res) => {
  res.statusCode = isHealthy ? 200 : 500;
  res.send()
});

router.get('/make-unhealthy', (req, res) => {
  isHealthy = false;
  res.send("Service will pretend to be unhealthy on next health check.")
});

app.use(router)