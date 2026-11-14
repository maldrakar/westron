---
paths:
  - "platforms/apple/**"
  - "Package.swift"
---

# Правила для Apple (SwiftUI)

## Форма API

- Стиль поверх системного контрола: `Button("Сохранить") { … }.buttonStyle(.primary, size: .m)`.
  Своих типов-обёрток (`WButton`) нет. Свой компонент — только когда системного нет (Badge, Banner, EmptyState),
  и его имя берётся из контракта без префикса (decisions/0003).
- Перечисления вариантов и размеров (`ButtonVariant`, `ButtonSize`) генерируются из контракта. Не пиши их руками.
- Размеры называются `s`, `m`, `l`, как в контракте. Значение по умолчанию учитывает `@Environment(\.controlSize)`.
- Состояния, которых нет у системного контрола (например, `loading`), задаются модификатором через окружение.
- Значение варианта не совпадает с именем системного стиля того же контрола (`plain`, `bordered`,
  `borderedProminent`, `borderless`, `automatic`, `link`, `glass`, `glassProminent`), иначе вызов неоднозначен.

## Значения

- Только токены. Сырые цвета, размеры, отступы, радиусы, прозрачность и анимация в `WestronUI` ловит хук
  и `npm run lint:raw-values`. Исключение — `// westron-lint: allow <причина>`, с настоящей причиной.
- Текст — через семантические текстовые роли и `Font.custom(_:size:relativeTo:)`, чтобы работал Dynamic Type.
  Масштабируемые отступы — через `@ScaledMetric`.

## Платформы

- Минимум: iOS 17, macOS 14, watchOS 10. Liquid Glass и другие API 26+ — внутри `if #available(iOS 26, macOS 26,
  watchOS 26, *)` с честной альтернативой для старых систем (decisions/0008).
- Liquid Glass — для элементов управления и навигации, не для слоя контента (HIG Materials).
- watchOS получает урезанное подмножество; что есть на часах — записано в блоке `platforms` контракта.
- Hover, фокус клавиатуры и указатель — состояния, в которые сенсорный iOS и watchOS просто не входят.
- Код, который нужен только одной платформе, — за `#if os(...)`; пакет должен компилироваться для всех трёх
  (`tools/apple/check.sh platforms`).

## Swift

- Swift 6, строгая конкурентность. Представления и их помощники — `@MainActor`.
- Тесты пакета — Swift Testing (`import Testing`). UI-тесты каталога — XCTest, потому что так требует XCUITest.
- Формат — `swift format` с конфигом `.swift-format`; хук форматирует файл после каждой правки.

## Каталог

- Каждый компонент добавляет запись в `Catalog.entries` (`platforms/apple/Sources/WestronCatalog/Catalog.swift`)
  в том же pull request; `id` записи равен `id` компонента в контракте.
- Запись рендерит матрицу вариантов, размеров и состояний из контракта, без навигации внутри.
- Проект каталога — `Catalog.xcodeproj/project.xcproj` в формате Xcode 27. Файлы подхватываются из папок
  `Catalog/` и `CatalogUITests/` сами; правь проект, только чтобы поменять настройки или таргеты.
- Смотри на результат: `tools/apple/catalog-screenshot.sh ios|macos --entry <id>` печатает путь к PNG.
  `ImageRenderer` и `cacheDisplay` для этого не годятся: на macOS они не видят содержимое SwiftUI.
