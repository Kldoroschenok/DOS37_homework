const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

let notes = [];

// Отдаём статику (CSS)
app.use(express.static(path.join(__dirname, 'public')));

// Главная страница с формой
app.get('/', (req, res) => {
  res.send(`
  <!DOCTYPE html>
  <html lang="ru">
  <head>
    <meta charset="UTF-8">
    <title>Личный дневник пользователя</title>
    <link rel="stylesheet" href="/style.css">
  </head>
  <body>
    <div class="container">
      <h1>Личный дневник</h1>
      <form action="/add" method="POST">
        <textarea name="text" placeholder="Ваша заметка..." required></textarea>
        <button type="submit">Добавить</button>
      </form>
      <p class="links">
        <a href="/notes">Список заметок (HTML)</a> |
        <a href="/api/notes" target="_blank">Список заметок (JSON)</a>
      </p>
    </div>
  </body>
  </html>
  `);
});

// Страница HTML со списком заметок
app.get('/notes', (req, res) => {
  const notesList = notes.length
    ? notes.map(n => `<li><span class="date">${n.date}</span>: ${n.text}</li>`).join('')
    : '<li>Пока заметок нет :(</li>';

  res.send(`
  <!DOCTYPE html>
  <html lang="ru">
  <head>
    <meta charset="UTF-8">
    <title>Заметки</title>
    <link rel="stylesheet" href="/style.css">
  </head>
  <body>
    <div class="container">
      <h1>Все заметки</h1>
      <ul class="notes">
        ${notesList}
      </ul>
      <p class="links">
        <a href="/">⬅ Назад</a>
      </p>
    </div>
  </body>
  </html>
  `);
});

// JSON вариант
app.get('/api/notes', (req, res) => {
  res.json({ notes });
});

// Добавление заметки
app.post('/add', (req, res) => {
  const { text } = req.body;
  if (!text) {
    return res.status(400).json({ error: 'Нет поля text' });
  }
  const newNote = { id: notes.length + 1, text, date: new Date().toLocaleString('ru-RU') };
  notes.push(newNote);
  res.redirect('/notes');
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Diary app listening on port ${PORT}`);
  });
}

module.exports = app;

//app.listen(PORT, () => {
//  console.log(`Diary app listening on port ${PORT}`);
//});

