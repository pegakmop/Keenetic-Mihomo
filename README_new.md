# Mihomo на роутерах Keenetic

Инструкция для запуска ядра **Mihomo** на роутерах **Keenetic**.

---

## ⚙️ Поддержка ядра

На данный момент поддержка Mihomo добавлена в **форк клиента xkeen**.  
Скоро она появится (или уже появилась) в официальной установке:

- [XKeen на GitHub](https://github.com/jameszeroX/XKeen)
- Рабочая бета версия xkeen с Mihomo от автора: [Инструкция в Telegram](https://t.me/c/2138190368/258/132588)

---

## 🧩 Пример конфигурации

В моём репозитории доступен пример конфигурации для Mihomo с маршрутизацией **Ru-Bundle от Легиза**:

- [config.yaml (raw)](https://raw.githubusercontent.com/OMchik33/Keenetic-Mihomo/refs/heads/main/config.yaml)
- Админ панель: [http://192.168.1.1:9090/ui](http://192.168.1.1:9090/ui)

---

## Установка конфига

Скачайте базовый конфигурационный файл:

```bash
curl -L -o /opt/etc/mihomo/config.yaml https://raw.githubusercontent.com/OMchik33/Keenetic-Mihomo/refs/heads/main/config.yaml
```

---

## Настройка

Откройте конфиг на редактирование и замените в блоке "ВАШИ ПРОКСИ СЕРВЕРЫ" заглушку `https://ссылкаподписки` на вашу ссылку подписки на ВПН

```
nano /opt/etc/mihomo/config.yaml
```

---

## 🖥 Подключение пользовательского интерфейса

Вы можете использовать различные пользовательские интерфейсы для управления Mihomo. Укажите один из URL в конфигурационном файле (`config.yaml`) в поле `external-ui-url`.

### Примеры:

- Интерфейс от MetaCubeX:

  ```yaml
  external-ui-url: "https://github.com/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz"
  ```

- Интерфейс Zashboard:

  ```yaml
  external-ui-url: "https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip"
  ```

---

## Особенности данного конфига:

* "Скопировал и работает", достаточно прописать ссылку на ВПН
* Правила маршрутизации Ru Bundle от Легиза + дополнительно Cloudflare, Telegram, Steam, WhatsApp
* По умолчанию Стим и Cloudflare идут в директ, но через веб интерфейс можно за пару кликов переключить их на ВПН
* Удобное управление через веб интерфейс режимами работы для Cloudflare, Telegram, Steam, WhatsApp, Youtube
* Автообновление прокси подписки и списка правил маршрутизации.

![image](https://github.com/user-attachments/assets/196b4357-4449-4f76-b9a5-b1ca2a14fab2)

---

## 🛠 Полезные инструменты

- [Документация по настройке Mihomo](https://wiki.metacubex.one/ru/config/)
- [Онлайн-конвертер подписок в YAML с маршрутизацией](https://dikozimpact.github.io/clash-convertor/)
- [Наборы правил маршрутизации от Legiz](https://github.com/legiz-ru/mihomo-rule-sets)

---

# Ответственность

Данный конфиг является примером настроки ядра Mihomo. Важно: соблюдайте законы страны проживания и страны, в которой работает прокси сервер. Прокси предназначен для безопасной и анонимной работы в интернет

Автор не несет ответственности за возможные варианты работы конфигурации ядра Михомо на различных устройствах и в различном окружении операционной системы, при использовании конфига вы несете полную ответственность за понимание его работы, настройку под конкретную ситуацию, задачу, устройство. Данный конфиг был опробован и проверен в работе в приложении XKeen с ядром Mihomo на роутере Keenetic.


