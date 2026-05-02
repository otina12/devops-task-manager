const request = require('supertest');
const app = require('../app/server');
const db = require('../app/db');

beforeEach(() => db.reset());

describe('GET /health', () => {
  it('returns status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('GET /tasks', () => {
  it('returns empty array initially', async () => {
    const res = await request(app).get('/tasks');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });
});

describe('POST /tasks', () => {
  it('creates a task', async () => {
    const res = await request(app).post('/tasks').send({ title: 'Buy milk' });
    expect(res.status).toBe(201);
    expect(res.body.title).toBe('Buy milk');
    expect(res.body.completed).toBe(false);
  });

  it('rejects empty title', async () => {
    const res = await request(app).post('/tasks').send({ title: '' });
    expect(res.status).toBe(400);
  });
});

describe('PATCH /tasks/:id', () => {
  it('toggles task completion', async () => {
    const created = await request(app).post('/tasks').send({ title: 'Test task' });
    const id = created.body.id;
    const res = await request(app).patch(`/tasks/${id}`);
    expect(res.status).toBe(200);
    expect(res.body.completed).toBe(true);
  });
});

describe('DELETE /tasks/:id', () => {
  it('deletes a task', async () => {
    const created = await request(app).post('/tasks').send({ title: 'Delete me' });
    const id = created.body.id;
    const del = await request(app).delete(`/tasks/${id}`);
    expect(del.status).toBe(204);
    const list = await request(app).get('/tasks');
    expect(list.body).toHaveLength(0);
  });
});
