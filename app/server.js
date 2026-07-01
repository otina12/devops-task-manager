const express = require('express');
const path = require('path');
const morgan = require('morgan');
const { register, metricsMiddleware } = require('./metrics');
const app = express();
const PORT = process.env.PORT || 3000;

if (process.env.NODE_ENV !== 'test') {
  app.use(morgan((tokens, req, res) => JSON.stringify({
    time: tokens.date(req, res, 'iso'),
    method: tokens.method(req, res),
    url: tokens.url(req, res),
    status: Number(tokens.status(req, res)),
    responseTimeMs: Number(tokens['response-time'](req, res)),
  })));
}

app.use(metricsMiddleware);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

app.use('/tasks', require('./routes/tasks'));

app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

if (require.main === module) {
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

module.exports = app;
