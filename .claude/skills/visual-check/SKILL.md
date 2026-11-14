---
name: visual-check
description: Снимает скриншоты записей каталога westron на iOS и macOS, открывает их и сверяет с контрактом и эталонами. Используй после любой правки, которая меняет вид компонента или каталога, и перед тем как показывать результат человеку.
argument-hint: "[id записи …] [--platform ios|macos]"
---

# Визуальная проверка каталога

Цель — увидеть результат своими глазами, а не предполагать. Скриншот, который не открыт, не считается.

## 1. Что снимать

- Если в аргументах есть id записей — их: `$ARGUMENTS`.
- Иначе — записи затронутых компонентов: каталоги в `spec/components/` и файлы в `platforms/apple/`, которые
  менялись (`git status`, `git diff main...HEAD --stat`). Id записи равен id компонента.
- Если ничего не подходит — служебная запись `environment`.

## 2. Снять

Для каждой записи, по умолчанию на обеих платформах:

```sh
tools/apple/catalog-screenshot.sh ios   --entry <id> --appearance light
tools/apple/catalog-screenshot.sh ios   --entry <id> --appearance dark
tools/apple/catalog-screenshot.sh ios   --entry <id> --dynamic-type accessibility3
tools/apple/catalog-screenshot.sh macos --entry <id> --appearance light
tools/apple/catalog-screenshot.sh macos --entry <id> --appearance dark
```

Скрипт печатает путь к PNG. Снимки независимы: запускай их по одному и не прерывай на первой ошибке.

Если macOS падает с `Timed out while enabling automation mode`, на машине не включён Automation Mode.
Включить его может только человек, один раз:
`! sudo automationmodetool enable-automationmode-without-authentication`. Скажи об этом и продолжи с iOS.

## 3. Посмотреть

Открой каждый PNG (Read) и проверь:

- все варианты, размеры и состояния из контракта `spec/components/<id>/<id>.spec.yaml` присутствуют;
- в тёмной теме нет «потерявшихся» элементов: текст читается, границы видны;
- на `accessibility3` текст не обрезан и не налезает, раскладка не сломана;
- iOS и macOS выглядят как одна система, а различия совпадают с блоком `platforms` контракта;
- если есть эталоны в `spec/components/<id>/reference/`, открой их и сравни.

## 4. Ответ

Для каждого снимка — путь и одна строка «что видно». Затем расхождения: что не так, на каком снимке,
предположительная причина. Если расхождение — пробел контракта, а не ошибка кода, так и скажи.
