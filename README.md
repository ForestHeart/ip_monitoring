# IP Monitoring System

Это приложение предназначено для мониторинга доступности IP-адресов и сбора статистики.

## Требования

- Docker
- Docker Compose

## Установка

### Клонируйте репозиторий:

```sh
git clone https://github.com/yourusername/ip-monitoring-system.git
cd ip-monitoring-system
```

## Запуск

1. Постройте и запустите контейнеры Docker:

    ```sh
    docker-compose up --build
    ```

2. Приложение будет доступно по адресу `http://localhost:9292`.

## Использование

### API

- **POST /ips** - добавить адрес с параметрами (enabled: bool, ip: ipv4/ipv6 address)
- **POST /ips/:id/enable** - включить сбор статистики ip
- **POST /ips/:id/disable** - выключить сбор статистики ip
- **GET /ips/:id/stats** - получить статистику для адреса (time_from: datetime, time_to: datetime)
- **DELETE /ips/:id** - выключить сбор и удалить адрес

### Пример запросов

#### Добавить IP-адрес
  ```sh
  curl -X POST http://localhost:9292/ips -H "Content-Type: application/json" -d '{"ip":"192.168.1.1","enabled":true}'
  ```

#### Получить статистику для IP-адреса
  ```sh
  curl -X GET "http://localhost:9292/ips/1/stats?time_from=2023-01-01T00:00:00Z&time_to=2023-01-02T00:00:00Z"
  ```

## Тестирование

1. Создайте и мигрируйте тестовую базу данных:
  ```sh
  docker-compose run app bundle exec rake db:create db:migrate RACK_ENV=test
  ```

2. Запуск тестов:
  ```sh
  docker-compose run app bundle exec rspec
  ```
