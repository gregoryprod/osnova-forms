# Установка администратором

## Исходное состояние (осмотр 2026-10-30)

VPS Ubuntu 24.04, 2 GiB RAM, свободно ~33 GiB диска. nginx/certbot есть. В PATH ruby и docker не обнаружены. Порт 3100 свободен на момент проверки. forms.osnova-mind.ru → 31.31.201.170, отдельного vhost и подходящего сертификата нет.
Основной сайт: /var/www/osnova-mind.ru. Существующие vhost основного сайта и Mini App не изменять, общему nginx разрешены только `nginx -t` и плавный reload, без restart.

## Перед выкладкой

1. Сделать снапшот VPS у провайдера; убедиться, что он завершён, записать ID/дату и порядок восстановления.
2. Сохранить nginx-конфиг, index.html и intake.js в каталог root-only вне webroot; записать SHA256 и убедиться, что копии читаются. Не включать env/ключи/базы в Git или общедоступные архивы.
3. Проверить текущие конфиги, свободный 3100, RAM/диск, успешность app.osnova-mind.ru до и после работ.
4. Установить Ruby 3.4.11 + Bundler и сборочные зависимости (gcc/make, openssl/zlib/yaml/sqlite dev). Шаблон unit ожидает /opt/ruby/3.4.11/bin; при другом пути изменить только этот unit.

## Приложение

Создать отдельного системного пользователя forms, без прав на Mini App. Разместить код в `/srv/osnova-forms/releases/<commit>` (копия без .git/секретов), `current` — симлинк на релиз. Базы — `/srv/osnova-forms/shared/storage`, доступ только forms.
`tmp` и `log` релиза доступны на запись forms, остальной код — на чтение. Установить gems для production: `bundle config set --local without 'test'`, `bundle install`.

Создать `/etc/osnova-forms/env` из .env.example: root:root 600. systemd читает его до снижения прав. Вставить токен напрямую на сервере, не через историю команд или репозиторий.
SECRET_KEY_BASE и три ENCRYPTION_* — независимые случайные строки, минимум 32 случайных байта в hex. Пример генерации отдельного значения: `openssl rand -hex 32` в закрытом терминале. Не менять ключи шифрования после начала приёма; резервировать отдельно.

До миграций экспортировать env только в закрытую root-сессию (`set -a; . /etc/osnova-forms/env; set +a`). Выполнить `bin/rails db:prepare` от forms с тем же окружением, путями Ruby и STORAGE_PATH. Команда должна создать и primary, и queue базу, включая recurring-таблицы; проверить владельца файлов forms.
В таком же окружении выполнить `bin/rails amo:check` — только чтение, проверяет аккаунт/воронку. Сверить поля контакта с config/intake_catalog.json; enum_id не перенумеровывать по sort.

Установить deploy/osnova-forms.service в /etc/systemd/system/, проверить путь Ruby, затем `systemctl daemon-reload` и `systemctl enable --now osnova-forms`. Проверить журнал, обе базы и локальный `/up` с заголовком Host:forms.osnova-mind.ru и X-Forwarded-Proto:https.

## nginx и HTTPS

1. Создать отдельный bootstrap vhost из forms.osnova-mind.ru.http.conf, каталог /var/www/letsencrypt. Включить только этот новый vhost, `nginx -t && systemctl reload nginx`.
2. `certbot certonly --webroot -w /var/www/letsencrypt -d forms.osnova-mind.ru` (администратор использует свой контакт и принимает условия провайдера сертификата).
3. Заменить только созданный vhost на forms.osnova-mind.ru.conf. `nginx -t && systemctl reload nginx`.
4. Проверить HTTPS /up, /embed.js, certbot renew --dry-run, штатный timer и deploy-hook плавного reload nginx после обновления сертификата. Существующие сертификаты не перевыпускать.
5. Если прямой доступ к api.telegram.org ограничен, задать ALERT_API_ROOT=https://<адрес-Worker> (без /bot<TOKEN>/sendMessage); ALERT_BOT_TOKEN и ALERT_CHAT_ID задать отдельно в env. Конечный слеш у базового адреса допустим. Настроить Telegram-бота и чат для ошибок и проверить уведомление с согласия владельца адресата. До этого форму не включать.

## Приёмка и сайт

Выполнить ACCEPTANCE.md; затем перенести deploy/site/intake.js.patch и script embed.js по deploy/site/README.md. Только после работающего HTTPS/API включать submissionReady. Проверить в браузере обычный и мобильный сценарии.

## Обновление / откат

Перед обновлением приложения — новый релиз и согласованный бэкап SQLite. Для целостной копии остановить ТОЛЬКО osnova-forms, либо использовать SQLite online backup; не копировать отдельно живой .sqlite3 без WAL. Зафиксировать версию схемы и сохранить соответствующие ключи. Бэкапы с ПДн root-only и зашифрованы при выносе; срок хранения согласовать.

Откат привязки: восстановить index.html/intake.js из проверенного бэкапа, изменить cache-busting.
Откат приложения: остановить osnova-forms, вернуть current на прежний совместимый релиз, запустить и проверить /up. При несовместимой миграции — согласованно восстановить БД и ключи из бэкапа, учитывая заявки после точки восстановления.
При аварии снять только новый forms vhost и `nginx -t && systemctl reload nginx`. Не останавливать общий nginx или Mini App. Недоставленные заявки сохранять.

## Разбор uncertain

Посмотреть submissions:status. В CRM найти source_uid (полный client_submission_id) и сверить неразобранное/сделки за время отправки, включая уже принятые заявки. Если создано — записать подтверждённые amo_uid/amo_lead_id/amo_contact_id и вернуть pending для примечания. Если достоверно не создано — вернуть pending и next_attempt_at=nil. При сомнении не повторять создание автоматически. После исправления failed вернуть pending отдельно. Записывать только ID, не содержимое анкет, в журнал инцидента.
