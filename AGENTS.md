# westron — инструкции для агентов

westron — дизайн-система для технических продуктов: один источник данных (токены, контракты компонентов,
язык дизайна) и нативная библиотека на каждой платформе. Пилотная платформа — Apple (SwiftUI),
пилотный продукт — [todo-app](https://github.com/maldrakar/todo-app) (decisions/0006).

Сейчас идёт фаза 0 «Каркас»; фазы — milestones на GitHub, задачи — issues.

## Где что лежит

| Путь | Что там |
|---|---|
| `decisions/` | Принятые решения (ADR). Читай перед тем, как менять подход |
| `design-language/` | Язык дизайна, главы `00–09` (фаза 1) |
| `tokens/` | Токены DTCG 2025.10 и резолвер режимов (фаза 1) |
| `spec/components/<id>/` | Контракт компонента `<id>.spec.yaml`, его решения и эталонные скриншоты (фаза 2) |
| `platforms/apple/Sources/WestronUI/` | Стили и компоненты SwiftUI — то, что подключают продукты |
| `platforms/apple/Sources/WestronCatalog/` | Реестр записей каталога, его хост; их же переиспользуют снапшот-тесты |
| `platforms/apple/Catalog/` | Приложение-каталог (iOS + macOS) и UI-тест скриншотов |
| `tools/` | Генераторы и проверки (TypeScript на Node 24) и скрипты для Apple |
| `Package.swift` | Манифест SwiftPM; лежит в корне, потому что так требует SwiftPM |

## Команды

Тулчейн: Xcode из `.xcode-version` (27.1, Swift 6.4) и Node 24. Скрипты сами находят нужный Xcode
и не трогают `xcode-select`. Если вызываешь `swift` или `xcodebuild` напрямую, сначала
`source tools/apple/xcode-env.sh`.

```sh
tools/apple/check.sh package      # swift build + swift test (macOS)
tools/apple/check.sh platforms    # компиляция для iOS и watchOS
tools/apple/check.sh catalog      # сборка приложения-каталога и UI-тестов
tools/apple/check.sh format       # swift format lint; исправить: tools/apple/check.sh fix-format
tools/apple/check.sh all          # всё сразу

tools/apple/catalog-screenshot.sh ios   --entry environment --appearance dark   # печатает путь к PNG
tools/apple/catalog-screenshot.sh macos --entry environment                     # то же на macOS

npm ci                            # один раз
npm test                          # тесты tools/
npm run typecheck
npm run lint:raw-values           # никаких сырых значений в WestronUI
npm run generate                  # перегенерировать код из источников; CI проверяет --check
```

Скриншот — способ увидеть свою работу: открой PNG и посмотри, прежде чем говорить «готово».
Параметры записи: `--appearance light|dark`, `--dynamic-type xSmall…accessibility5`, `--device "iPhone 17"`.

## Правила

1. **Контракт раньше кода.** Компонент реализуется по утверждённому контракту в `spec/components/`.
   Если при реализации нашёлся пробел, сначала правится контракт, потом код (decisions/0005).
2. **Только токены.** В `WestronUI` нет сырых цветов, размеров, отступов, радиусов, прозрачности
   и анимаций. Осознанное исключение помечается `// westron-lint: allow <причина>`.
3. **Системный контрол важнее своего.** Если на платформе есть нативный компонент, westron даёт стиль
   и расширения, а не обёртку; префиксов вроде `WButton` нет (decisions/0003).
4. **Одинаковые имена генерируются.** Значения вариантов, размеров и состояний берутся из контракта
   через генератор. Сгенерированные файлы не правятся руками.
5. **Паритет записан.** Расхождение между платформами без записи в блоке `platforms` контракта — баг.
6. **Новый компонент — только под потребность пилота.** У контракта заполнено поле `consumers`.
7. **Доказательства, а не слова.** Вместо «тесты прошли» — команда и её вывод или скриншот.
8. **Минимум ОС — как у пилота:** iOS 17, macOS 14, watchOS 10. API новее — через
   `if #available` (decisions/0008).
9. **Язык.** Документы, комментарии и сообщения — на русском; идентификаторы в коде — на английском.

## Решения

- [0001](decisions/0001-shared-contract-not-shared-ui.md) общий контракт вместо общей UI-библиотеки
- [0002](decisions/0002-platforms-and-stacks.md) платформы и стеки
- [0003](decisions/0003-styles-on-system-controls.md) стили поверх системных контролов и форма API
- [0004](decisions/0004-source-formats.md) форматы источника данных
- [0005](decisions/0005-workflow.md) процесс работы и три точки утверждения
- [0006](decisions/0006-pilot-product.md) пилотный продукт и его экраны
- [0007](decisions/0007-license.md) лицензии
- [0008](decisions/0008-apple-toolchain-and-catalog.md) Apple: версии, тулчейн, каталог и скриншоты

Итоговый отчёт исследования с источниками: `reports/`.
