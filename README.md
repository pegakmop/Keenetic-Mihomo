# Mihomo на роутерах Keenetic

Скрипт и инструкция для запуска ядра **Mihomo** на роутерах **Keenetic**.

---

## ⚙️ Поддержка ядра

На данный момент поддержка Mihomo добавлена в **форк клиента xkeen**.  
Скоро она появится (или уже появилась) в официальной установке:

- [XKeen на GitHub](https://github.com/jameszeroX/XKeen)
- Временная инструкция от автора: [Инструкция в Telegram](https://t.me/c/2138190368/258/132588)

---

## 📥 Установка

```sh
opkg update >/dev/null 2>&1
opkg upgrade >/dev/null 2>&1
opkg install curl tar
curl -L https://raw.githubusercontent.com/jameszeroX/xkeen/main/beta/xkeen.tar -o xkeen.tar
tar -xvf xkeen.tar -C /opt/sbin --overwrite > /dev/null && rm xkeen.tar
xkeen -i
```

---

## 🔄 Обновление

```sh
opkg update >/dev/null 2>&1
opkg upgrade >/dev/null 2>&1
curl -L https://raw.githubusercontent.com/jameszeroX/xkeen/main/beta/xkeen.tar -o xkeen.tar
tar -xvf xkeen.tar -C /opt/sbin --overwrite > /dev/null && rm xkeen.tar
xkeen -k
```

---

## 🧩 Пример конфигурации

В моём репозитории доступен пример конфигурации для Mihomo с маршрутизацией **Ru-Bundle от Легиза**:

- [config.yaml (raw)](https://raw.githubusercontent.com/OMchik33/Keenetic-Mihomo/refs/heads/main/config.yaml)
- [Наборы правил от Legiz](https://github.com/legiz-ru/mihomo-rule-sets)

---

## 🛠 Полезные инструменты

- [Документация по настройке Mihomo](https://wiki.metacubex.one/ru/config/)
- [Онлайн-конвертер подписок в YAML с маршрутизацией](https://dikozimpact.github.io/clash-convertor/)
