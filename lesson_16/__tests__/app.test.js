const request = require('supertest');
const app = require('../server');

describe('Diary App', () => {
  it('GET / should return main page with HTML', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
    expect(res.text).toContain('Личный дневник');
  });

  it('POST /add should add a new note and redirect', async () => {
    const res = await request(app)
      .post('/add')
      .send('text=Тестовая заметка')
      .set('Content-Type', 'application/x-www-form-urlencoded');
    expect(res.status).toBe(302); // redirect to /notes
    expect(res.header.location).toBe('/notes');
  });

  it('GET /notes should contain added note', async () => {
    const res = await request(app).get('/notes');
    expect(res.status).toBe(200);
    expect(res.text).toContain('Тестовая заметка');
  });

  it('GET /api/notes should return JSON array with notes', async () => {
    const res = await request(app).get('/api/notes');
    expect(res.status).toBe(200);
    expect(res.body.notes.length).toBeGreaterThan(0);
    expect(res.body.notes[0]).toHaveProperty('text', 'Тестовая заметка');
  });
});

