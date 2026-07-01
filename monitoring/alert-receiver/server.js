const express = require('express');
const app = express();
const PORT = process.env.PORT || 5001;

app.use(express.json());

const alerts = [];

app.post('/alerts', (req, res) => {
  const incoming = (req.body && req.body.alerts) || [];
  incoming.forEach((a) => {
    const entry = {
      time: new Date().toISOString(),
      status: a.status,
      name: a.labels && a.labels.alertname,
      severity: a.labels && a.labels.severity,
      summary: a.annotations && a.annotations.summary,
    };
    alerts.unshift(entry);
    console.log('[ALERT]', JSON.stringify(entry));
  });
  res.sendStatus(200);
});

app.get('/alerts', (req, res) => res.json(alerts.slice(0, 50)));

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.get('/', (req, res) => {
  res.set('Content-Type', 'text/html');
  res.end('<h1>Alert Receiver</h1><pre>' + JSON.stringify(alerts.slice(0, 50), null, 2) + '</pre>');
});

app.listen(PORT, () => console.log(`alert-receiver listening on ${PORT}`));
