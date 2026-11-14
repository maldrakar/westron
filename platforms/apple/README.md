# westron для Apple

SwiftUI-библиотека для iOS, iPadOS, macOS и watchOS. Манифест пакета лежит в корне репозитория.

| Путь | Что там |
|---|---|
| `Sources/WestronUI/` | Стили и компоненты — то, что подключают продукты |
| `Sources/WestronCatalog/` | Записи каталога, их хост и аргументы запуска |
| `Tests/` | Тесты пакета (Swift Testing) |
| `Catalog/` | Приложение-каталог для iOS и macOS и UI-тест скриншотов |

## Подключение

```swift
.package(url: "https://github.com/maldrakar/westron", from: "0.1.0")
// …
.product(name: "WestronUI", package: "westron")
```

## Каталог

Открыть в Xcode 27.1: `platforms/apple/Catalog/Catalog.xcodeproj`. Без аргументов каталог показывает навигацию
по всем записям. С `-WestronEntry <id>` — одну запись на весь экран; так её снимает
`tools/apple/catalog-screenshot.sh`.

### Скриншоты на macOS: один раз включить Automation Mode

UI-тесты на macOS, через которые снимаются скриншоты, требуют Automation Mode. Включить его без запроса пароля
при каждом запуске:

```sh
sudo automationmodetool enable-automationmode-without-authentication
```

Почему не `screencapture` и не снимок внутри процесса — в decisions/0008.
