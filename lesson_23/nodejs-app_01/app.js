const express = require('express');
const Memcached = require('memcached');
const app = express();
const port = 3000;

// Подключение к Memcached
const memcached = new Memcached(process.env.MEMCACHED_HOST || 'localhost:11211');

// Маршрут для записи/чтения данных
app.get('/', async (req, res) => {
  const key = 'test_key';
  const value = { timestamp: Date.now() };

  try {
    // Запись в кэш (на 60 секунд)
    await new Promise((resolve, reject) => {
      memcached.set(key, value, 60, (err) => err ? reject(err) : resolve());
    });

    // Чтение из кэша
    const cachedData = await new Promise((resolve, reject) => {
      memcached.get(key, (err, data) => err ? reject(err) : resolve(data));
    });

    res.json({
      message: 'Данные успешно записаны и прочитаны из Memcached!',
      cached: cachedData,
      status: 'success'
    });
  } catch (error) {
    console.error('Memcached error:', error);
    res.status(500).json({ error: 'Memcached operation failed', status: 'error' });
  }
});

app.listen(port, () => {
  console.log(`Сервер запущен на порту ${port}`);
});
