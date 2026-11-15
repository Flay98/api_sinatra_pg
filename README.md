# REST API рекрутинга на Sinatra и PostgreSQL

Практические работы из частей 2–4: Sinatra, PostgreSQL и Sequel. Приложение
хранит компании, вакансии, соискателей и отклики. API возвращает JSON и работает
по адресу `http://localhost:4567`, основное пространство имён — `/api/v1`.

Проект расположен в `~/RubymineProjects/api_sinatra_pg`. Проект первой
лабораторной `api_rails_pg` не используется и не изменяется.

## Окружение и зависимости

Проверено на Ubuntu 24.04, Ruby 3.3.6 и PostgreSQL 18.4. Версии зависимостей
зафиксированы в `Gemfile.lock`: Sinatra / sinatra-contrib 4.2.1,
Sequel 5.110.0, sequel-seed 1.1.2, Rack 3.2.8, Puma 8.0.3,
pg 1.7.0, Bundler 4.0.12. Тесты используют Minitest и Rack::Test.
Rails и ActiveRecord в зависимости приложения не входят.

## Быстрый запуск

```bash
cd ~/RubymineProjects/api_sinatra_pg
ruby -v
bundle config set --local path vendor/bundle
bundle install
```

При первоначальной настройке скопируйте `.env.example` в `.env` и заполните
`PGPASSWORD` паролем существующей роли `yanik_pryanik`. Если `.env` уже настроен,
сохраните его. Файл исключён из Git, локально ему установлены права `600`.

```bash
# Только при отсутствии .env:
cp -n .env.example .env
chmod 600 .env
```

В текущем окружении PostgreSQL слушает **5433**, поэтому этот порт указан
в шаблоне. Если ваш сервер использует другой порт, измените `PGPORT`.

```bash
bundle exec rake db:create
bundle exec rake db:migrate db:seed db:check
bundle exec rake test
bin/server
```

В другом терминале:

```bash
curl http://localhost:4567/api/v1/companies
curl 'http://localhost:4567/api/v1/jobs?name=Ruby&place=Remote'
bundle exec ruby bin/smoke
```

Остановка сервера: `Ctrl+C` в терминале, где он запущен.

### Другие способы запуска

Через Rack, как в методичке, с явно указанным портом:

```bash
bundle exec rackup -o 127.0.0.1 -p 4567 config.ru
```

Прямой запуск модульного приложения:

```bash
bundle exec ruby api_sinatra_postgres.rb
```

Классический стиль из части 2 вынесен в самостоятельный пример:

```bash
bundle exec ruby examples/classic.rb
```

Эти варианты используют один порт; запускайте один сервер за раз.
Классический пример не требует подключения к БД.

### RubyMine

Откройте директорию проекта и выберите интерпретатор Ruby 3.3.6.
В `.run/Sinatra development.run.xml` сохранена конфигурация запуска.
Выберите **Sinatra development** в списке Run/Debug Configurations.
Она запускает `api_sinatra_postgres.rb` из корня проекта с `RACK_ENV=development`.
Bundler и `.env` загружаются самим приложением.

Если IDE не импортировала конфигурацию автоматически, откройте
**Run → Edit Configurations → + → Ruby**, задайте:

| Поле | Значение |
| --- | --- |
| Name | Sinatra development |
| Ruby script | `$PROJECT_DIR$/api_sinatra_postgres.rb` |
| Working directory | `$PROJECT_DIR$` |
| Ruby SDK | 3.3.6 |
| Environment | `RACK_ENV=development` |

Графический запуск в RubyMine отдельно не проверялся; запуск того же Ruby-скрипта
проверен из терминала.

## Подключение к PostgreSQL

`config/environment.rb` загружает `.env`, а `config/database.rb` создаёт соединение
Sequel. Уже заданные переменные процесса имеют приоритет над `.env`.

| Переменная | Значение по умолчанию |
| --- | --- |
| `RACK_ENV` | `development` |
| `PGHOST` | `localhost` |
| `PGPORT` | `5433` |
| `PGUSER` | `yanik_pryanik` |
| `PGPASSWORD` | Задаётся локально |
| `DB_MAX_CONNECTIONS` | `5` |
| `PORT` | `4567` |

Имя базы фиксируется по окружению:

| Окружение | База |
| --- | --- |
| development | `api_sinatra_pg_development` |
| test | `api_sinatra_pg_test` |
| production | `api_sinatra_pg_production` |

`PGDATABASE` и `DATABASE_URL` намеренно не переопределяют этот выбор: случайная
переменная от другого проекта не должна направить миграции или seeds в его БД.
Неизвестный `RACK_ENV` отклоняется. Перед изменением схемы и загрузкой seeds
проверяется фактическое имя подключённой базы.

Все три базы созданы существующей ролью `yanik_pryanik`. Действующих прав роли
оказалось достаточно; роль и настройки аутентификации не изменялись.
Миграции применены во всех трёх базах, учебные данные — в development и test.
Production остаётся без учебных данных.

Если переносите проект на другую машину, роли нужны LOGIN и возможность
создать эти три базы либо уже созданные администратором базы в её владении.
`db:create` работает только с указанными именами и пропускает существующие базы.
Суперпользователь для работы приложения не требуется.

Проверка соединения и примеров Dataset:

```bash
bundle exec rake db:check db:version db:datasets
bundle exec ruby bin/console
```

В консоли доступны `DB`, `Company`, `Job`, `Geek`, `Apply`:

```ruby
dataset = DB[:companies]
dataset.count
dataset.all
dataset.select(:id, :name).order(:name).where { id < 3 }.all
Company.by_name('mo').by_location('ne').all
Job.by_name('ruby').place('remote').all
```

Для подключения через Database в RubyMine: PostgreSQL → host `localhost`,
port `5433`, user `yanik_pryanik`, database `api_sinatra_pg_development`;
пароль вводится локально. Затем **Test Connection → Apply → OK**.

## Структура проекта

```text
api_sinatra_postgres.rb   Sinatra::Base, JSON, обработчики ошибок, загрузка маршрутов
config.ru                Rack entrypoint
Gemfile / Gemfile.lock   Зависимости и точные версии
Rakefile                 Загрузка Rake-задач и тестов
.env.example             Шаблон переменных окружения
.run/                    Конфигурация RubyMine
config/                  Загрузка окружения, соединение Sequel, настройки Puma
models/                  Company, Job, Geek, Apply, сериализация, scopes, валидации
controllers/             Общие REST-обработчики четырёх ресурсов
helpers/                 JSON, параметры, типы, фильтрация, поиск записей
routes/                  Маршруты по моделям и учебные примеры
db/migrations/           Четыре последовательные миграции Sequel
seeds/                   Очистка и четыре файла заполнения с префиксами даты
lib/                     Запуск миграций, Sequel::Seed и Rake-задачи
examples/classic.rb      Классический стиль из части 2
bin/server               Puma на 127.0.0.1:4567
bin/console              Консоль Sequel/IRB
bin/smoke                Проверка настоящих HTTP-запросов
test/                    Автоматические тесты на PostgreSQL
postman/                 Коллекция из 77 запросов
docs/                    Сопоставление реализации с заданиями
```

## Схема и модели

У всех таблиц есть `id` (integer primary key), `created_at`, `updated_at`
(timestamp). Поля `name`, `location`, `place`, `stack` имеют тип PostgreSQL `text`.
`resume` — **boolean**, как в миграции методички, а не текст резюме.

| Модель | Поля предметной области | Связи |
| --- | --- | --- |
| Company | name, location | one_to_many jobs |
| Job | name, place, company_id | many_to_one company; one_to_many applies; many_to_many geeks |
| Geek | name, stack, resume=false | one_to_many applies; many_to_many jobs |
| Apply | job_id, geek_id, read=false, invited=false | many_to_one job, geek |

Обязательные текстовые поля проверяются на пустоту; ссылки — на существование.
Внешние ключи, NOT NULL и CHECK-ограничения дополнительно действуют в БД.
Удаление записи с зависимостями возвращает 409. Сначала удаляйте отклики,
затем вакансии/соискателей и компании. Каскадное удаление через API не применяется.
Плагины Sequel заполняют timestamps при создании/изменении через модели.
У исходных seed-записей timestamps равны `null`, как в примерах методички.

## Миграции и seeds

Все команды запускаются из корня проекта:

```bash
bundle exec rake db:migrate
bundle exec rake 'db:migrate[3]'
bundle exec rake db:version
bundle exec rake db:migrate --trace
bundle exec rake db:rollback        # На одну версию назад
bundle exec rake 'db:rollback[0]'   # До нулевой версии
bundle exec rake db:migrate db:seed
```

Rollback удаляет соответствующие таблицы и их данные. При понижении версии
очищается журнал seeds, чтобы после восстановления схемы можно было загрузить
данные заново. Integer-миграции Sequel хранят версию в `schema_info`;
`schema_migrations` нужен для другого, timestamp-формата миграций и здесь не создаётся.

Первый `db:seed` выполняет пять файлов по порядку: очистка → companies → jobs →
geeks → applies. `TRUNCATE ... RESTART IDENTITY` очищает только четыре таблицы
проекта и сбрасывает последовательности. Все файлы и `schema_seeds` применяются
в одной транзакции. `pg_advisory_xact_lock` защищает от одновременного запуска seeds.

Повторный `db:seed` пропускает файлы из `schema_seeds` и сохраняет новые записи.
Для **явной перезагрузки учебных данных с удалением текущих данных этого проекта**:

```bash
RESEED=1 bundle exec rake db:seed
```

Эта команда автоматически очищает журнал `schema_seeds`, затем снова выполняет
очистку и вставки. Ручное удаление строк в RubyMine не требуется.
Учебные seeds запрещены в production.

Реализован `db:reset`, который откатывает и восстанавливает всю схему.
Он требует точного имени базы в `CONFIRM_RESET` и **при выполнении работы не запускался
с разрешением удаления**:

```bash
# УДАЛЯЕТ данные выбранной базы проекта:
CONFIRM_RESET=api_sinatra_pg_development bundle exec rake db:reset
```

Для другого окружения указывайте `RACK_ENV` перед командой:

```bash
RACK_ENV=test bundle exec rake db:migrate
RACK_ENV=production bundle exec rake db:migrate
```

### Исходные данные

4 компании: MoGo / New York, Wirkkle / London, Artesis / Saint-Petersburg,
BuildEmpire / London. 7 вакансий: Sinatra React, Ruby React, React,
Node React, Ruby on Rails, Node, Javascript CSS HTML — с компаниями и местом работы
из части 4. Название вакансии Ruby on Rails не означает использование Rails в приложении.

В предоставленных документах нет полного списка из девяти соискателей;
для них добавлен согласованный учебный набор в `seeds/202611140004_geeks.rb`.
Четыре отклика соответствуют первым четырём записям примеров части 4:
прочитаны 1 и 3, не прочитаны 2 и 4, приглашение есть у 3.
Более поздние демонстрационные вакансии 8/11 и отклики 5/6 не включены,
чтобы сохранить требуемые количества 4/7/9/4.

## API endpoints

База URL: `http://localhost:4567`. Все перечисленные ниже ресурсные пути
начинаются с `/api/v1`.

### CRUD четырёх ресурсов

Для каждого `resource` из `companies`, `jobs`, `geeks`, `applies`:

| Метод | Путь | Результат |
| --- | --- | --- |
| GET / HEAD | `/{resource}` | Список; 200 |
| GET / HEAD | `/{resource}/:id` | Запись с timestamps; 200 или 404 |
| POST | `/{resource}` | Создание; 201 и заголовок Location |
| PUT | `/{resource}/:id` | Замена полей ресурса; обязательные поля нужны целиком |
| PATCH | `/{resource}/:id` | Обновление переданных полей |
| DELETE | `/{resource}/:id` | Удаление; 200 с JSON-сообщением |
| OPTIONS | `/*` | Список поддерживаемых методов; 200 и Allow |

PUT сохраняет идентификатор и timestamps создания; пропущенные boolean-поля
получают исходное значение `false`. PATCH сохраняет все непереданные поля.
HEAD возвращает заголовки GET без тела по стандарту HTTP.

Списки содержат предметные поля без timestamps и отсортированы по `id`.
Одиночная запись содержит также `created_at` и `updated_at`.
Булевы значения сериализуются в JSON `true`/`false`, ID — числами.

### Фильтры списков

| Путь | Query-параметры |
| --- | --- |
| `/companies` | name, location |
| `/jobs` | name, place, company (название), company_id |
| `/geeks` | name, stack, resume |
| `/applies` | job_id, geek_id, read, invited |

Текстовый поиск — по подстроке без учёта регистра; несколько фильтров соединяются
через AND. Символы `%`, `_`, `\` и регулярные выражения трактуются как обычный текст.
Пустой текстовый фильтр не ограничивает выборку. Нулевой результат — `[]` и 200.
Boolean-фильтры принимают `true` или `false`, ID — положительные integer.
Помимо `&`, поддержан разделитель `;` в query string, используемый в методичке.

### Специальные маршруты и адреса методички

| Метод | Путь | Результат |
| --- | --- | --- |
| GET | `/company/:id` | Компания, alias `/companies/:id` |
| GET | `/job/:id` | Вакансия, alias `/jobs/:id` |
| GET | `/geek/:id` | Соискатель, alias `/geeks/:id` |
| GET | `/apply/:id` | Отклик, alias `/applies/:id` |
| GET | `/companies/:id/jobs` | Вакансии компании по ID; нет компании → 404 |
| GET | `/company_jobs?name=Mo` | Вакансии всех компаний, совпавших по части названия |
| GET | `/jobs_company/:name` | Вакансии компании с точным названием; нет компании → 404 |
| GET | `/jobs/:id/applies` | Отклики на вакансию |
| GET | `/geeks/:id/jobs` | Вакансии, на которые откликнулся соискатель |
| GET | `/geeks/:id/applies` | Отклики соискателя |
| GET | `/applies_read` | Прочитанные отклики |
| GET | `/applies_unread` | Непрочитанные отклики |

У существующей компании без вакансий ответ — `[]`, 200.
`/company_jobs?name=Missing` также возвращает `[]`.

### Примеры запросов

```bash
curl 'http://localhost:4567/api/v1/companies?name=Mo;location=Ne'
curl http://localhost:4567/api/v1/company/2
curl 'http://localhost:4567/api/v1/company_jobs?name=Mo'
curl http://localhost:4567/api/v1/applies_unread
curl http://localhost:4567/api/v1/jobs_company/MoGo
curl http://localhost:4567/api/v1/job/111

curl -i -X POST http://localhost:4567/api/v1/companies \
  -H 'Content-Type: application/json' \
  -d '{"name":"Dieter","location":"Ubud"}'
```

Тело запроса — JSON-объект с полями модели. Также принимаются
`application/x-www-form-urlencoded` и, при пустом теле, query-параметры
из POST-примера методички. Запись ID и timestamps клиентом запрещена;
неизвестные поля возвращают 422.

### Учебные маршруты части 2

Вне `/api/v1`: `/`, `/hello/:name`, `/redirect` (302 → `/hello/World`),
`/players/:sport_id`, `/players/*/:year`, `/say/*/to/*`, `/download/*.*`,
regex-примеры `/meta/hello/world`, `/meta/hello/12345/world`, `/hello/world/1234`,
`/jobs`, `/jobs.json`, `/jobs.xml`, `/friends`.
Внутри namespace также доступен `/api/v1/friends`.
Даже суффикс `.xml` в учебном примере возвращает JSON, согласно заданию.
В части 4 некоторые URL напечатаны без namespace: их ресурсные версии здесь
приведены к единому `/api/v1`; корневой `/jobs` сохраняет учебный пример части 2.
Неизвестный путь возвращает 404 с JSON и информацией о пути/splat.
В отдельном классическом примере показан общий wildcard-маршрут `/*`.

### Ошибки

| Статус | Когда |
| --- | --- |
| 400 | Некорректный ID, тип query-параметра, повреждённый JSON или JSON не объект |
| 404 | Нет записи/маршрута/компании для точного поиска |
| 409 | Удалению мешают внешние ключи или нарушена уникальность |
| 415 | Неподдерживаемый Content-Type тела запроса |
| 422 | Валидация полей, неизвестные атрибуты, несуществующая ссылка |
| 500 | Непредвиденная серверная ошибка; внутренние детали не возвращаются |

```json
{"message":"Document Not Found","status":404,"params_id":"111"}
```

## Проверки и Postman

```bash
bundle exec rake test
# При запущенном сервере:
bundle exec ruby bin/smoke
```

Тесты всегда выбирают `api_sinatra_pg_test`, применяют миграции и pending seeds.
Каждый тест обёрнут в транзакцию с откатом; отдельно проверяются реальные
ограничения PostgreSQL, обратимость миграций, сброс последовательностей,
идемпотентность seeds и защита `db:reset`. Development/production тестами не затрагиваются.

HTTP smoke выполняет 32 запроса к настоящему серверу, включая CRUD всех моделей,
фильтры и ошибки. Он создаёт собственные временные записи и удаляет их
в обратном порядке зависимостей даже при ошибке. Последовательности ID при этом
продолжают расти — это нормальное поведение PostgreSQL.

Коллекция: `postman/api_sinatra_pg.postman_collection.json` (Postman v2.1).
Импортируйте её через **Import → File**. Переменная `base_url` уже содержит
`http://localhost:4567`. В коллекции 77 запросов с проверками статусов и JSON,
отдельные папки для фильтров, связей, CRUD, ошибок и маршрутов части 2.
CRUD-папки запускайте целиком через Collection Runner: POST сохраняет ID
в переменную, DELETE удаляет созданную запись. Перед запуском нужны seeds.

Перечень выполненных заданий и адаптаций: `docs/lab_checklist.md`.
Результаты проверок записаны в `docs/verification.md`.

Официальная документация, использованная при адаптации:
[Sinatra](https://sinatrarb.com/intro.html),
[Namespace](https://sinatrarb.com/contrib/namespace),
[Sequel validations](https://sequel.jeremyevans.net/rdoc/files/doc/validations_rdoc.html).
