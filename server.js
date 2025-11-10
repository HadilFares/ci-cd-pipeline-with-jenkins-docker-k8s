const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('API Node.js avec Jenkins & K8s');
});

// Health check pour Kubernetes
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Ready check
app.get('/ready', (req, res) => {
  res.json({ status: 'ready' });
});

app.listen(port, () => {
  console.log(`✅ Server running at http://localhost:${port}`);
});