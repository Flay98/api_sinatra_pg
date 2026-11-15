# Выполненные задания частей 2–4

Основной запрос пользователя задаёт объём работы и ограничения. Методички
использованы как учебная спецификация; устаревшие команды адаптированы к
Ruby 3.3.6, Sinatra 4, Rack 3 и PostgreSQL 18.4.

## Часть 2 — Sinatra

| Задание | Реализация / проверка |
| --- | --- |
| Проверить Ruby, установить Sinatra и зависимости | Ruby 3.3.6, Gemfile / Gemfile.lock, bundle install |
| Классический стиль: корень, приветствие, wildcard | examples/classic.rb; отдельный исполняемый пример |
| Модульный стиль Sinatra::Base | Recruitment::App в api_sinatra_postgres.rb |
| Запуск Ruby-скриптом | App.run! только при непосредственном запуске файла |
| Запуск через Rack | config.ru; rackup -p 4567 |
| Namespace /api/v1 | Sinatra::Namespace для всех ресурсных маршрутов |
| Порядок маршрутов и wildcard | Явные маршруты, затем JSON 404; общий splat в classic.rb |
| Именованные параметры | /hello/:name, /players/:sport_id |
| Splat и параметры блока | /say/*/to/*, /download/*.*, /players/*/:year |
| Regex-маршруты | /meta/hello/world, /meta/hello/12345/world, /hello/world/1234 |
| Необязательный format | /jobs, /jobs.json, /jobs.xml; всегда JSON |
| Redirect | /redirect → /hello/World, HTTP 302 с JSON |
| Проверки внутри/вне namespace | /friends и /api/v1/friends |
| Структура и загрузка проекта | config, helpers, models, controllers, routes, lib; явная загрузка моделей и контроллеров, сортированная загрузка routes |
| RubyMine | .run/Sinatra development.run.xml и пошаговая инструкция README |

Оба учебных стиля сохранены раздельно, чтобы их маршруты не влияли друг на друга.
Основной проект использует модульный стиль. Вместо старых Thin/WEBrick используется
Puma; в Rack 3 rackup устанавливается отдельным gem.

## Часть 3 — PostgreSQL и Sequel

| Задание | Реализация / проверка |
| --- | --- |
| Отдельные development/test/production базы | db:create; три api_sinatra_pg_* |
| Роль и пароль | Существующая yanik_pryanik; PGPASSWORD в локальном .env |
| Подключение Sequel | config/database.rb; db:check |
| Соответствие окружения базе | Фиксированная карта имён; отказ от чужих DATABASE_URL/PGDATABASE |
| Company, Job, Geek, Apply | models/*.rb, ассоциации, валидации |
| Типы из методички | text, integer FK, boolean resume/read/invited, timestamps |
| Четыре миграции | db/migrations/001…004; версия 4 |
| db:migrate, db:rollback, db:reset, db:version, db:seed | lib/tasks/db.rb, запускаются через bundle exec rake |
| Диагностика --trace | Стандартный Rake --trace; пароли не печатаются |
| Seeds с префиксами даты | 5 файлов в seeds/, сортировка по номеру |
| Очистка с зависимостями | TRUNCATE четырёх таблиц одной командой без CASCADE |
| Сброс primary key | RESTART IDENTITY; проверяется тестом |
| Sequel::Seed и schema_seeds | Sequel.extension :seed; Sequel::Seed.setup; Sequel::Seeder.apply |
| Повторная загрузка seeds | RESEED=1 очищает журнал в транзакции; обычный запуск сохраняет данные |
| 4 компании / 7 вакансий / 9 соискателей / 4 отклика | Seed-файлы; тесты количества и внешних ключей |
| Консоль Sequel | bundle exec ruby bin/console, без пароля в командной строке |
| Dataset all/count/select/order/where | db:datasets, примеры README и тесты scopes |
| JSON-сериализация модели и коллекции | to_api, to_detail, collection_to_api |
| Маршруты по ресурсам | routes/companies.rb, jobs.rb, geeks.rb, applies.rb |

Схема сохраняет `resume` как boolean. Опечатка `upated_at` исправлена на
`updated_at`. Вместо неисполняемого YAML с Ruby-кодом используется конфигурация
Ruby и dotenv. Integer-миграции используют `schema_info`; журнал seeds —
`schema_seeds`. Ручная очистка таблиц журнала заменена воспроизводимой задачей.

Настройка `trust` и выдача роли статуса superuser из старого учебного примера
не применялись: пользователь явно потребовал сохранить защиту PostgreSQL.

## Часть 4 — конечные точки

| Задание | Endpoint / реализация |
| --- | --- |
| Список компаний | GET /api/v1/companies |
| name, location, их сочетание, пустая выборка | Company.by_name + dataset by_location; тесты `&` и `;` |
| Компания по ID | GET /api/v1/company/:id, /companies/:id |
| Вакансии компании | /company_jobs?name=Mo, /companies/:id/jobs |
| Company scopes двумя способами | self.by_name и dataset_module by_location |
| Создание компании | POST /companies, JSON/form/query, HTTP 201 |
| Прочитанные/непрочитанные отклики | /applies_read, /applies_unread; scopes Apply.read/unread |
| Список и фильтрация вакансий | /jobs?name=…&place=…&company=…&company_id=… |
| Вакансии по точному имени компании | /jobs_company/:name |
| Вакансия по ID | /job/:id, /jobs/:id |
| Нет записи | JSON 404 с message, status, params_id |
| Проверка Postman | postman/api_sinatra_pg.postman_collection.json, 77 запросов |

Дополнительно согласно запросу пользователя выполнены CRUD всех четырёх моделей,
списки/фильтры соискателей и откликов, связанные ресурсы, проверка типов,
обработка ошибок и автоматические тесты на настоящем PostgreSQL.

## Уточнения к исходным данным

Документы показывают разные состояния таблиц после ручных запросов, включая
вакансии с ID 8/11 и отклики 5/6. Использованы первые семь вакансий и первые четыре
отклика, чтобы соблюсти количества из запроса пользователя. Девять соискателей
добавлены как учебный набор: полного перечня в документах нет.

Frontend, авторизация, Docker, Rails/ActiveRecord, отчёт DOCX и Git push
в состав работы не включены согласно ограничениям пользователя.
