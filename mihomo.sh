#!/bin/sh
echo "По всем вопросам установочного скрипта пишите в лс @pegakmop погнали разбираться с установкой mihomo"
sleep 5
echo ">>> Проверка среды Entware/OpenWRT..."
if ! command -v opkg >/dev/null 2>&1; then
  echo "❌ Команда 'opkg' не найдена. Убедитесь, что вы используете Entware/OpenWRT-среду."
  exit 1
fi

echo ">>> [0/7] Проверка компонента и подготовка к настройке"
ip_address_router=$(ip addr show br0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)

if ndmc -c "components list" | grep -A15 "name: proxy" | grep "installed:"; then
    echo "✅ Компонент клиент прокси установлен на роутере"
    echo "⏳ Устанавливаю Proxy0 и политику mihomo..."
    ndmc -c "no interface Proxy0" >/dev/null 2>&1
    ndmc -c "interface Proxy0"
    ndmc -c "interface Proxy0 description Proxy0-$ip_address_router:7890"
    ndmc -c "interface Proxy0 proxy protocol socks5"
    ndmc -c "interface Proxy0 proxy socks5-udp"
    ndmc -c "interface Proxy0 proxy upstream $ip_address_router 7890"
    ndmc -c "interface Proxy0 up"
    ndmc -c "interface Proxy0 ip global 1"
    ndmc -c "no ip policy mihomo"
    ndmc -c "ip policy mihomo"
    ndmc -c "ip http ssl port 8443"
    ndmc -c "system configuration save"
    echo "✅ Proxy0, политика mihomo созданы и сохранены, SSL порт веб интерфейса успешно перенесен с 443 на 8443!"
else
    echo "❌ Компонент КЛИЕНТ ПРОКСИ не установлен!"
    echo "➡️ В веб-интерфейсе Keenetic: http://$ip_address_router"
    echo "В боковом меню ищем → Параметры системы → Изменить набор компонентов → Клиент прокси → включите галочку и сохраните."
    echo "❗️Роутер перезагрузится после сохранения, для установки компонента клиент прокси. ⚠️ Потом запустите данный скрипт заново"
    exit 1
fi

set -e

# В CLI роутера: http://192.168.1.1/a
#ip http ssl port 8443
#system configuration save

rm -rf /opt/etc/mihomo/
echo ">>> [1/7] Определение архитектуры..."
ARCH=$(uname -m)
case "$ARCH" in
  aarch64)  MIHOMO_ARCH="arm64" ;;
  armv7l|armv7) MIHOMO_ARCH="armv7" ;;
  mips)     MIHOMO_ARCH="mips" ;;
  mipsel)   MIHOMO_ARCH="mipsle" ;;
  x86_64)   MIHOMO_ARCH="amd64" ;;
  *) echo "❌ Неизвестная архитектура: $ARCH"; exit 1 ;;
esac
echo ">>> Архитектура: $ARCH → $MIHOMO_ARCH"

echo ">>> [2/7] Проверка и установка зависимостей..."
NEED_UPDATE=0
REQUIRED_PKGS="curl jq nano iptables coreutils-nohup mc unzip ip-full"
for pkg in $REQUIRED_PKGS; do
  if ! opkg list-installed | grep -q "^$pkg "; then
    NEED_UPDATE=1; break
  fi
done
[ "$NEED_UPDATE" -eq 1 ] && opkg update
for pkg in $REQUIRED_PKGS; do
  opkg list-installed | grep -q "^$pkg " || opkg install "$pkg"
done

if ! curl -Is https://github.com | head -n 1 | grep -q "200\|301"; then
  echo "❌ GitHub недоступен. Проверьте подключение к интернету или DNS."
  exit 1
fi

echo ">>> [3/7] Проверка последней версии Mihomo..."
LATEST_VERSION=$(curl -s https://github.com/MetaCubeX/mihomo/releases | grep -Eo "/MetaCubeX/mihomo/releases/tag/v[0-9.]+" | head -n 1 | cut -d '/' -f6)
echo ">>> Последняя версия: $LATEST_VERSION"

echo ">>> [4/7] Подготовка директорий..."
mkdir -p /opt/sbin /opt/etc/mihomo/ui /opt/etc/init.d /opt/var/log /opt/var/run

echo ">>> [5/7] Загрузка и установка Mihomo..."
cd /opt/sbin
BIN_URL="https://github.com/MetaCubeX/mihomo/releases/download/${LATEST_VERSION}/mihomo-linux-${MIHOMO_ARCH}-${LATEST_VERSION}.gz"
curl -LO "$BIN_URL"
gunzip "mihomo-linux-${MIHOMO_ARCH}-${LATEST_VERSION}.gz"
mv "mihomo-linux-${MIHOMO_ARCH}-${LATEST_VERSION}" mihomo
chmod +x mihomo
./mihomo -v

echo ">>> [6/7] Настройка автозапуска..."
curl -L -o /opt/etc/init.d/S99mihomo https://raw.githubusercontent.com/pegakmop/Keenetic-Mihomo/refs/heads/main/S99mihomo
chmod +x /opt/etc/init.d/S99mihomo
grep -q "alias mihomo=" ~/.profile || echo "alias mihomo='/opt/etc/init.d/S99mihomo'" >> ~/.profile
. ~/.profile


echo ">>> [7/7] Загрузка конфигурации по умолчанию..."
echo "Выберите конфигурацию для скачивания:"
echo "1 - config.yaml"
echo "2 - configdomain.yaml"
read -p "Введите 1 или 2: " choice

if [ "$choice" = "1" ]; then
    curl -L -o /opt/etc/mihomo/config.yaml \
    https://raw.githubusercontent.com/pegakmop/Keenetic-Mihomo/refs/heads/main/config.yaml
    echo "Скачан config.yaml"
elif [ "$choice" = "2" ]; then
    curl -L -o /opt/etc/mihomo/config.yaml \
    https://raw.githubusercontent.com/pegakmop/Keenetic-Mihomo/refs/heads/main/configdomain.yaml
    echo "Скачан configdomain.yaml"
else
    echo "Неверный выбор. Перезапустите скрипт и выберите 1 или 2."
    exit 1
fi


# === Установка UI ===
UI_DIR="/opt/etc/mihomo/ui/"
TMP_ZIP="/tmp/zashboard.zip"
TMP_TGZ="/tmp/metacubexd.tgz"

echo
echo "🔘 Выберите веб-интерфейс:"
echo "1) Zashboard UI"
echo "2) MetaCubeXD UI"
printf "Введите 1 или 2 и нажмите Enter: "
read choice

echo ">>> Очистка старого UI..."
mkdir -p "$UI_DIR"

if [ "$choice" = "1" ]; then
  echo ">>> Установка Zashboard UI..."
  TMP_UNZIP_DIR="/tmp/zashboard_unpack"
  rm -rf "$TMP_UNZIP_DIR"
  mkdir -p "$TMP_UNZIP_DIR"

  curl -L -o "$TMP_ZIP" "https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip"
  unzip "$TMP_ZIP" -d "$TMP_UNZIP_DIR"
  rm "$TMP_ZIP"

  if [ -d "$TMP_UNZIP_DIR/dist" ]; then
    cp -r "$TMP_UNZIP_DIR/dist/"* "$UI_DIR"
    echo "✓ Установлен Zashboard UI в $UI_DIR"
  else
    echo "❌ Не найдена папка dist/ в архиве Zashboard"
  fi

  rm -rf "$TMP_UNZIP_DIR"

elif [ "$choice" = "2" ]; then
  echo ">>> Установка MetaCubeXD UI..."
  curl -L -o "$TMP_TGZ" "https://github.com/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz"
  tar -xzf "$TMP_TGZ" -C "$UI_DIR"
  rm "$TMP_TGZ"
  echo "✓ Установлен MetaCubeXD UI в $UI_DIR"
else
  echo "✗ Неверный выбор. Перезапустите скрипт и выберите 1 или 2."
  exit 1
fi

# === Автозамена подписки ===
printf "\n🔑 Введите ссылку на вашу подписку (например, https://sub.example.com/abcd123): "
read subscription_url

if [ -n "$subscription_url" ]; then
  CONFIG_PATH="/opt/etc/mihomo/config.yaml"
  TMP_PATH="/tmp/config.yaml.tmp"

  awk -v newurl="$subscription_url" '
    BEGIN { in_sub = 0 }
    {
      if ($0 ~ /^[[:space:]]*sub:[[:space:]]*$/) {
        in_sub = 1
        print $0
        next
      }

      if (in_sub && $0 ~ /^[[:space:]]*url:[[:space:]]*/) {
        sub(/url:.*/, "url: " newurl, $0)
        in_sub = 0
      }

      print $0
    }
  ' "$CONFIG_PATH" > "$TMP_PATH" && mv "$TMP_PATH" "$CONFIG_PATH"

  echo "✓ Подписка обновлена в proxy-providers → sub → url"
else
  echo "⚠️ Подписка не введена. Вставьте вручную позже в config.yaml"
fi

# === Финал ===

echo "⚠️На данный момент проверена установка только на архитектуре aarch64 за остальным еще нужно проверять"
echo "✅ Установка Mihomo завершена!"
echo "⚠️ Выберите только провайдера в приоритетах подключений в политике mihomo и сохраните, а так же закиньте нужное устройство в политику mihomo"
echo "Команды управления mihomo в терминале:"
echo "▶️ Запуск: mihomo restart"
echo "📵 Остановка: mihomo stop"
echo "♻️ Статус: mihomo status"
echo "📝 Конфиг: /opt/etc/mihomo/config.yaml"
echo "🌐 WebUI-доступ: http://$ip_address_router:9090/ui"

sleep 6
rm "$0"

