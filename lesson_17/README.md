# Auto Orders API

Простое FastAPI-приложение с PostgreSQL без миграций.

## Возможности

- `GET /health` — проверяет наличие соединения с БД.
- `GET /models` — возвращает доступные модели авто.
- `GET /orders` — возвращает созданные заказы.

При старте приложение само создает таблицы, если их нет, и заполняет список моделей начальными данными.

## Технологии

- Python 3.12+
- FastAPI
- PostgreSQL
- psycopg3

## Структура проекта

```text
app/
  main.py
  requirements.txt
  README.md
```

## Установка

### Локально

Установите зависимости:

```bash
pip install -r requirements.txt
```

Создайте переменную окружения `DATABASE_URL`:

```bash
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/autos"
```

Запустите приложение:

```bash
uvicorn main:app --reload
```

После старта API будет доступно на:

```text
http://localhost:8000
```

## Переменные окружения

- `DATABASE_URL` — строка подключения к PostgreSQL.

Пример:

```text
postgresql://postgres:postgres@db:5432/autos
```

## Эндпоинты

### `GET /health`

Проверяет подключение к PostgreSQL.

Ответ при успехе:

```json
{"status":"ok"}
```

### `GET /models`

Возвращает список доступных моделей авто.

Пример ответа:

```json
[
  {"id": 1, "name": "Tesla Model 3", "price": 45000},
  {"id": 2, "name": "BMW X5", "price": 75000},
  {"id": 3, "name": "Toyota Camry", "price": 35000}
]
```

### `GET /orders`

Возвращает список заказов.

Пример ответа:

```json
[
  {
    "id": 1,
    "customer_name": "Ivan Petrov",
    "created_at": "2026-08-04T10:30:00",
    "model": {
      "id": 1,
      "name": "Tesla Model 3",
      "price": 45000
    }
  }
]
```

## Схема БД

Приложение использует две таблицы:

- `car_models` — модели авто.
- `orders` — заказы.

Таблицы создаются автоматически при старте, миграции не нужны.

## Примечания

- Если таблица `car_models` пустая, приложение добавляет начальные модели.
- Для простоты соединение с БД открывается на каждый запрос.
- Проект намеренно сделан минималистичным.

## Пример проверки

```bash
curl http://localhost:8000/health
curl http://localhost:8000/models
curl http://localhost:8000/orders
```
