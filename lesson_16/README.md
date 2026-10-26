# Simple personal diary
Простой личный дневник на Node.js с использованием Express.  
Данные хранятся в памяти (без внешней базы), UI стилизован в чёрно-оранжевой гамме.  
В комплекте Dockerfile и набор автотестов с Jest+Supertest.

## Структура проекта
```bash
├── Dockerfile
├── README.md
├── __tests__
│   └── app.test.js
├── package.json
├── public
│   └── style.css
└── server.js
```

---

## Функционал

- `/` — главная страница с выбором: добавить заметку, посмотреть список, получить JSON
- `/add` — страница с формой для добавления заметки
- POST `/add` — добавление заметки, редирект на `/notes`
- `/notes` — страница с красивым списком заметок
- `/api/notes` — JSON со всеми заметками

---

## Локальная установка с помощью docker

1. Клонировать репозиторий или скопировать файлы проекта
2. Собрать image
```bash
docker build -t ${IMAGE}:${TAG} .
```
3. Запустить контейнер
```bash
docker run -d -it --name ${APP_NAME} -p 3000:3000 ${IMAGE}:${TAG}
```
где
- `${IMAGE}` - название docker image, например `diary-app`
- `${TAG}` - тег, например `v01`
- `${APP_NAME}` - имя контейнера, например `dos-29-diary-app`

4. Открыть в браузере [http://localhost:3000](http://localhost:3000)

---

## Тесты

В проекте настроены автотесты с Jest и Supertest.
```bash
# локально
npm test
# в контейнере
docker run --rm ${IMAGE}:${TAG} npm test
```
результат тестов сохраняется в файл `tests-result.json`.

---

## Примеры запросов

### Добавить заметку через curl
```bash
curl -X POST http://localhost:3000/add -d "text=Пример заметки" -H "Content-Type: application/x-www-form-urlencoded"
```

### Получить список заметок в JSON
```bash
curl http://localhost:3000/api/notes
```

### Открыть страницы в браузере
- Главная: `http://localhost:3000/`
- Добавить заметку: `http://localhost:3000/add`
- Список заметок: `http://localhost:3000/notes`
