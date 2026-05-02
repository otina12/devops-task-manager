const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/', (req, res) => res.json(db.getAll()));

router.post('/', (req, res) => {
  const { title } = req.body;
  if (!title || !title.trim()) return res.status(400).json({ error: 'Title required' });
  const task = db.create(title.trim());
  res.status(201).json(task);
});

router.patch('/:id', (req, res) => {
  const task = db.toggle(Number(req.params.id));
  if (!task) return res.status(404).json({ error: 'Not found' });
  res.json(task);
});

router.delete('/:id', (req, res) => {
  const ok = db.remove(Number(req.params.id));
  if (!ok) return res.status(404).json({ error: 'Not found' });
  res.status(204).send();
});

module.exports = router;
