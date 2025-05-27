# Keenetic-Mihomo
Инструкция по установке ядра Михомо на роутеры Кенетик

На примере роутера Keenetic Hopper SE с архитектурой aarch64.
Все действия производятся внутри Entware, которая уже должна быть установлена.

---

## Узнаем архитектуру своего роутера, если нужно:

```
uname -m
```

## Скачиваем нужную архитектуру ядра михомо  отсюда: https://github.com/MetaCubeX/mihomo/releases
* Копируем в папку /opt/bin
* Делаем исполняемым


* Либо вот код, если он еще работает (код для архитектуры aarch64):

```
# Пример ссылки, замените на актуальную!
MIHOMO_LATEST_URL="https://github.com/metacubex/mihomo/releases/download/v1.19.9/mihomo-linux-arm64-v1.19.9.gz" # Актуализируйте эту ссылку!

# Скачиваем архив
wget "$MIHOMO_LATEST_URL" -O /tmp/mihomo.gz

# Распаковываем
gunzip /tmp/mihomo.gz

# Перемещаем исполняемый файл в /opt/bin и даем права на выполнение
mv /tmp/mihomo /opt/bin/mihomo
chmod +x /opt/bin/mihomo

# Проверяем версию. Будет понятно нужной архитектуры скачали или не запустится, если ошиблись.
mihomo -v
```

## Создаем необходимые директории для работы Mihomo

```
mkdir -p /opt/etc/mihomo
mkdir -p /opt/var/log
mkdir -p /opt/var/run
```

## Создаем конфиг `nano /opt/etc/mihomo/config.yaml`

Пример конфига (при втавке в nano может быть проблема с русским шрифтом, я это обошел через редактор из MC):

```
# Общие настройки
port: 7890                     # HTTP proxy port (если нужен прямой доступ к HTTP прокси)
socks-port: 7891               # SOCKS5 proxy port (если нужен прямой доступ к SOCKS5 прокси)
mixed-port: 7893               # HTTP и SOCKS5 прокси на одном порту
redir-port: 7892               # Порт для прозрачного проксирования TCP (REDIRECT в iptables)
# tproxy-port: 7894            # Порт для прозрачного проксирования TCP и UDP (TPROXY, требует доп. настройки)
allow-lan: true                # Разрешить подключения из локальной сети. Можно указать IP роутера для большей безопасности.
mode: rule                     # Режим работы: rule (по правилам), global (через один прокси), direct (напрямую)
log-level: info                # Уровень логирования: debug, info, warning, error, silent
external-controller: '0.0.0.0:9090' # API для управления Mihomo (например, через веб-интерфейс Yacd)
                                     # '0.0.0.0' делает его доступным с других устройств в LAN
external-ui: "/opt/etc/mihomo/dashboard" # Путь к файлам веб-интерфейса (например, Yacd). Их нужно скачать отдельно. Если не нужно, обязательно закомментируйте эту строку

sniffer:
  enable: true
  force-dns-mapping: true
  parse-pure-ip: true
  sniff:
    HTTP:
      ports:
      - 80
      - 8080-8880
      override-destination: true
    TLS:
      ports:
      - 443
      - 8443

# Настройки DNS (Mihomo может выступать как DNS-сервер)
* За правила маршрутизации благодарность уважаемому Легизу: https://github.com/legiz-ru/mihomo-rule-sets
dns:
  enable: true
  listen: 0.0.0.0:5353         # Порт для DNS-запросов (не используйте 53, если он занят DNS-сервером Keenetic)
  ipv6: false                  # Включить разрешение IPv6 DNS, если необходимо
  default-nameserver:
    - 223.5.5.5                # DNS-серверы по умолчанию
    - 114.114.114.114
  enhanced-mode: fake-ip       # fake-ip или redir-host
  fake-ip-range: 198.18.0.1/16 # Диапазон для fake-ip
  nameserver:
    - https://dns.google/dns-query # DNS over HTTPS
    - tls://dns.google:853         # DNS over TLS
  fallback:                      # Резервные DNS, если основные не отвечают
    - https://1.1.1.1/dns-query
  # Пути к geoip.dat и geosite.dat (Mihomo ищет их в директории, указанной флагом -d при запуске)
  # geoip-dat: geoip.dat
  # geosite-dat: geosite.dat

# --- ВАШИ ПРОКСИ-СЕРВЕРЫ ---
# Замените этот раздел вашими реальными настройками прокси.
# Это просто пример, адаптируйте его под вашего провайдера.
proxies:
- name: MYVPN
  type: vless
  server: remnanoda.domain.com
  port: 443
  network: tcp
  udp: true
  tls: true
  servername: remnanoda.domain.com
  reality-opts:
    public-key: здесьвставленулинкальныйкодсамизнаетекакой
    short-id: здесьвставьтетожесамизнаетечто
  client-fingerprint: chrome
  uuid: здесьвытожезнаетечтовставитьнужно
  flow: xtls-rprx-vision

# --- ГРУППЫ ПРОКСИ (ПОЛИТИКИ) ---
proxy-groups:
  - name: MIHOMO  # Взяли и придумали такое название группы. Оно же будет использоваться ниже в конфиге
    type: select # Тип группы: select (ручной выбор), url-test (автовыбор по скорости), fallback (переключение при отказе)
    proxies:
      - MYVPN # Включите сюда имена прокси из раздела "proxies"
      # - "ДругойМойСервер"
      # - "DIRECT" # Можно добавить опцию прямого соединения
      # - "REJECT" # Можно добавить опцию блокировки
    # Пример для url-test:
    # type: url-test
    # url: 'http://www.gstatic.com/generate_204' # URL для проверки доступности
    # interval: 300 # Интервал проверки в секундах

# --- ПРАВИЛА МАРШРУТИЗАЦИИ ---
# Эти правила определяют, какой трафик куда направлять.

rule-providers:
  discord_domains:
    type: http
    behavior: domain
    format: mrs
    url: https://github.com/MetaCubeX/meta-rules-dat/raw/meta/geo/geosite/discord.mrs
    path: ./rule-sets/discord_domains.mrs
    interval: 86400
  discord_voiceips:
    type: http
    behavior: ipcidr
    format: mrs
    url: https://github.com/legiz-ru/mihomo-rule-sets/raw/main/other/discord-voice-ip-list.mrs
    path: ./rule-sets/discord_voiceips.mrs
    interval: 86400
  refilter_domains:
    type: http
    behavior: domain
    format: mrs
    url: https://github.com/legiz-ru/mihomo-rule-sets/raw/main/re-filter/domain-rule.mrs
    path: ./re-filter/domain-rule.mrs
    interval: 86400
  refilter_ipsum:
    type: http
    behavior: ipcidr
    format: mrs
    url: https://github.com/legiz-ru/mihomo-rule-sets/raw/main/re-filter/ip-rule.mrs
    path: ./re-filter/ip-rule.mrs
    interval: 86400
  youtube:
    type: http
    behavior: domain
    format: mrs
    url: https://github.com/MetaCubeX/meta-rules-dat/raw/meta/geo/geosite/youtube.mrs
    path: ./rule-sets/youtube.mrs
    interval: 86400
  oisd_big:
    type: http
    behavior: domain
    format: mrs
    url: https://github.com/legiz-ru/mihomo-rule-sets/raw/main/oisd/big.mrs
    path: ./oisd/big.mrs
    interval: 86400
  torrent-trackers:
    type: http
    behavior: domain
    format: mrs
    url: https://github.com/legiz-ru/mihomo-rule-sets/raw/main/other/torrent-trackers.mrs
    path: ./rule-sets/torrent-trackers.mrs
    interval: 86400
  torrent-clients:
    type: http
    behavior: classical
    format: yaml
    url: https://github.com/legiz-ru/mihomo-rule-sets/raw/main/other/torrent-clients.yaml
    path: ./rule-sets/torrent-clients.yaml
    interval: 86400
  ru-bundle:
    type: http
    behavior: domain
    format: mrs
    url: https://github.com/legiz-ru/mihomo-rule-sets/raw/main/ru-bundle/rule.mrs
    path: ./ru-bundle/rule.mrs
    interval: 86400

rules:
  # Примеры правил (если используете geoip.dat и geosite.dat):
  # - DOMAIN-SUFFIX,telegram.org,MIHOMO   # Трафик для telegram.org через Xkeen
  # - GEOSITE,google,MIHOMO               # Трафик для доменов из списка "google" через Xkeen
  # - GEOIP,CN,MIHOMO                     # Трафик на IP-адреса Китая через Xkeen
  # - DST-PORT,22,DIRECT                  # SSH-трафик напрямую
  - OR,((DOMAIN,ipwho.is),(DOMAIN,api.ip.sb),(DOMAIN,ipapi.co),(DOMAIN,ipinfo.io)),MIHOMO
  - RULE-SET,oisd_big,REJECT
  - OR,((RULE-SET,torrent-clients),(RULE-SET,torrent-trackers)),DIRECT
  - RULE-SET,youtube,MIHOMO
  - OR,((RULE-SET,discord_domains),(RULE-SET,discord_voiceips)),MIHOMO
  - RULE-SET,ru-bundle,MIHOMO
  - RULE-SET,refilter_domains,MIHOMO
  - RULE-SET,refilter_ipsum,MIHOMO
  - MATCH,DIRECT # все что не в правилах идет в ДИРЕКТ
```

## DNS через Михомо
Если будет нужно, в настройках ДНС в админке роутера поставьте 192.168.1.1:5353, а остальные ДНС выключите. Должно работать, но я не проверял

## Создание скрипта автозагрузки
Создайте файл `nano /opt/etc/init.d/S99mihomo` со следующим содержимым. Этот скрипт будет запускать Mihomo при старте роутера и позволит управлять им.

```
#!/bin/sh

# Entware init script for Mihomo

# === Configuration ===
ENABLED=yes
PROCS="mihomo" # Имя процесса
MIHOMO_BIN="/opt/bin/mihomo"
MIHOMO_DIR="/opt/etc/mihomo" # Рабочая директория Mihomo (где config.yaml, geoip.dat и т.д.)
# Mihomo ищет config.yaml в директории, указанной -d
ARGS="-d ${MIHOMO_DIR}"
PID_FILE="/opt/var/run/mihomo.pid"
LOG_FILE="/opt/var/log/mihomo.log" # Лог-файл
# === End Configuration ===

# Source Entware init functions
if [ -f /opt/etc/init.d/rc.func ]; then
    . /opt/etc/init.d/rc.func
else
    echo "Error: /opt/etc/init.d/rc.func not found." >&2
    exit 1
fi

# Create necessary directories if they don't exist
ensure_dirs() {
    mkdir -p "$(dirname "${PID_FILE}")"
    mkdir -p "$(dirname "${LOG_FILE}")"
    mkdir -p "${MIHOMO_DIR}"
}

start_mihomo() {
    ensure_dirs
    if [ -f "${PID_FILE}" ] && kill -0 "$(cat "${PID_FILE}")" >/dev/null 2>&1; then
        echo "${PROCS} is already running."
        return 0
    fi

    echo "Starting ${PROCS}..."
    # Запуск Mihomo в фоновом режиме, вывод логов в файл
    nohup ${MIHOMO_BIN} ${ARGS} > ${LOG_FILE} 2>&1 &
    # Сохраняем PID процесса
    echo $! > ${PID_FILE}

    if [ $? -eq 0 ]; then
        echo "${PROCS} started with PID $(cat ${PID_FILE})."
    else
        echo "Error starting ${PROCS}."
        rm -f "${PID_FILE}"
        return 1
    fi
}

stop_mihomo() {
    if [ ! -f "${PID_FILE}" ]; then
        echo "${PROCS} is not running (PID file not found)."
        # Можно попытаться найти и убить процесс по имени, если PID файла нет
        # pkill -f "${PROCS} ${ARGS}"
        return 0
    fi

    PID=$(cat "${PID_FILE}")
    echo "Stopping ${PROCS} (PID ${PID})..."

    if ! kill -0 "${PID}" >/dev/null 2>&1; then
        echo "Process ${PID} not found. Removing stale PID file."
        rm -f "${PID_FILE}"
        return 0
    fi

    # Посылаем SIGTERM для корректного завершения
    kill "${PID}"
    # Ждем немного
    COUNT=0
    while kill -0 "${PID}" >/dev/null 2>&1; do
        sleep 1
        COUNT=$((COUNT + 1))
        if [ ${COUNT} -ge 10 ]; then # Ждем до 10 секунд
            echo "${PROCS} (PID ${PID}) did not stop gracefully, sending SIGKILL."
            kill -9 "${PID}"
            break
        fi
    done

    if ! kill -0 "${PID}" >/dev/null 2>&1; then
        echo "${PROCS} stopped."
    else
        echo "Failed to stop ${PROCS} (PID ${PID})."
    fi
    rm -f "${PID_FILE}"
}

case "$1" in
    start)
        [ "${ENABLED}" = "yes" ] || exit 1
        start_mihomo
        ;;
    stop)
        stop_mihomo
        ;;
    restart)
        stop_mihomo
        sleep 1
        start_mihomo
        ;;
    status)
        if [ -f "${PID_FILE}" ]; then
            PID=$(cat "${PID_FILE}")
            if kill -0 "${PID}" >/dev/null 2>&1; then
                echo "${PROCS} is running (PID ${PID})."
            else
                echo "${PROCS} is not running (stale PID file: ${PID_FILE})."
            fi
        else
            # Дополнительная проверка по имени процесса, если нет PID файла
            if pgrep -f "${MIHOMO_BIN} ${ARGS}" >/dev/null; then
                 echo "${PROCS} is running (found by process name), but PID file is missing."
            else
                 echo "${PROCS} is not running."
            fi
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
```

## Сделайте скрипт исполняемым:
```
chmod +x /opt/etc/init.d/S99mihomo
```

## Вебинтерфейс для управления Mihomo
Если не нужен, тогда закомментируйте в конфиге строку `external-ui: "/opt/etc/mihomo/dashboard"`

* Скачиваем последнюю версию веб админки отсюда: https://github.com/MetaCubeX/metacubexd/releases

Нам нужен архив compressed-dist.tgz.

Распаковываем содержимое в `/opt/etc/mihomo/dashboard`

## Запускаем Mihomo

```
/opt/etc/init.d/S99mihomo start
```

Проверяем статус

```
/opt/etc/init.d/S99mihomo status
```

## Заходим в админку для проверки

```
http://192.168.1.1:9090/ui/
```

# НАСТРАИВАЕМ ПЕРЕНАПРАВЛЕНИЕ КЛИЕНТОВ РОУТЕРА В МИХОМО

## Настройка клиентов роутера

Важно: всем клиентам роутера, кто будет работать через Mihomo, нужно установить статичный (постоянный) IP адрес. Запишите их куда-нибудь для подстановки в скрипт

## Временый тест через IPTABLES

* Допустим наш клиент имеет адрес 192.168.1.111, тогда для теста будем использовать следующий код

```
Включить правило
iptables -t nat -A PREROUTING -i br0 -s 192.168.1.111 -p tcp -j REDIRECT --to-port 7892
Отключить правило
iptables -t nat -D PREROUTING -i br0 -s 192.168.1.111 -p tcp -j REDIRECT --to-port 7892
```

* Включаем тестово любой наш клиент роутера и проверяем работу прокси через ядро Mihomo. После проверки выключаем правило

## Делаем правила перенаправления постоянными

* Создадим файл `nano /opt/etc/ndm/netfilter.d/10-mihomo-redirect.sh`

```
#!/bin/sh
# Скрипт для добавления правил iptables для Mihomo

# Убедитесь, что LAN интерфейс (например, br0) уже поднят,
# и Mihomo уже слушает порт.
# Можно добавить небольшую задержку для надежности, если нужно.
sleep 10

LAN_IF="br0" # Имя вашего LAN интерфейса
MIHOMO_REDIR_PORT="7892" # Ваш redir-port

# Очистка предыдущих правил (опционально, если правила могут дублироваться)
# Это более сложная логика, если правила добавляются многократно.
# Проще всего добавлять их один раз при старте.

# IP-адреса клиентов для Mihomo
CLIENT_IPS="192.168.1.111 192.168.1.102" # Добавьте сюда IP ваших клиентов через пробел

for CLIENT_IP in $CLIENT_IPS; do
  # Проверяем, существует ли уже такое правило, чтобы не дублировать (упрощенная проверка)
  if ! iptables -t nat -C PREROUTING -i $LAN_IF -s $CLIENT_IP -p tcp -j REDIRECT --to-port $MIHOMO_REDIR_PORT > /dev/null 2>&1; then
    iptables -t nat -A PREROUTING -i $LAN_IF -s $CLIENT_IP -p tcp -j REDIRECT --to-port $MIHOMO_REDIR_PORT
    logger -t mihomo-redirect "Added iptables rule for $CLIENT_IP to Mihomo"
  fi
done

# Если используете ipset:
# ipset create mihomo_clients hash:ip > /dev/null 2>&1
# ipset add mihomo_clients 192.168.1.101
# ipset add mihomo_clients 192.168.1.102
# if ! iptables -t nat -C PREROUTING -i $LAN_IF -p tcp -m set --match-set mihomo_clients src -j REDIRECT --to-port $MIHOMO_REDIR_PORT > /dev/null 2>&1; then
#    iptables -t nat -A PREROUTING -i $LAN_IF -p tcp -m set --match-set mihomo_clients src -j REDIRECT --to-port $MIHOMO_REDIR_PORT
#    logger -t mihomo-redirect "Added iptables rule for ipset mihomo_clients to Mihomo"
# fi
```

* Делаем скрипт исполняемым

```
chmod +x /opt/etc/ndm/netfilter.d/10-mihomo-redirect.sh
```

Заключение: данный скрипт еще обкатывается, я не успел проверить код из блока "Делаем правила перенаправления постоянными", а вот в ручном применении правил через IPTABLES все работало
