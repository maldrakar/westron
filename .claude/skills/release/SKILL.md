---
name: release
description: Выпускает новую версию westron — CHANGELOG, тег и GitHub Release. Третья точка утверждения; вызывает только человек.
disable-model-invocation: true
argument-hint: "[major|minor|patch]"
---

# Релиз westron

Одна версия на весь репозиторий; SwiftPM берёт её из тега (decisions/0005). Тег — голая semver-версия
без префикса: `0.2.0`, не `v0.2.0`.

## Состояние на момент вызова

- Ветка: !`git branch --show-current`
- Незакоммиченное: !`git status --porcelain | head -20`
- Последний тег: !`git describe --tags --abbrev=0 2>/dev/null || echo "тегов нет"`
- Коммиты после него: !`git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD | head -40`
- CI на HEAD: !`gh run list --branch main --limit 3 --json headSha,conclusion,status,workflowName --jq '.[] | "\(.workflowName) \(.headSha[0:7]) \(.status) \(.conclusion)"' 2>/dev/null`

## Шаги

1. **Предусловия.** Ветка `main`, рабочее дерево чистое, `main` совпадает с `origin/main` (`git fetch` и сравнение),
   последний запуск CI на этом коммите зелёный. Если что-то не так — остановись и скажи, что именно.
2. **Версия.** Если человек передал `major|minor|patch` (`$ARGUMENTS`), используй это. Иначе предложи сам по
   разделу «Не выпущено» в `CHANGELOG.md` и коммитам: до 1.0 несовместимое изменение — это minor.
   Без тегов первая версия — `0.1.0`. Покажи итоговую версию и дождись подтверждения.
3. **CHANGELOG.** Перенеси «Не выпущено» в раздел `## <версия> — <ГГГГ-ММ-ДД>`. Только изменения, заметные
   потребителю. Несовместимые изменения — в подраздел «Миграция» с конкретными шагами для продукта.
   Оставь пустой раздел «Не выпущено» сверху.
4. **Проверки.** `tools/apple/check.sh all`, `npm test`, `npm run generate:check` — приложи вывод.
5. **Коммит и тег.** `git commit -m "Release <версия>"`, `git tag -a <версия> -m "<версия>"`.
6. **Публикация.** Покажи человеку diff CHANGELOG и команды ниже, дождись явного «да», затем:
   `git push origin main <версия>` и `gh release create <версия> --title <версия> --notes-file <файл с разделом версии>`.
7. **Итог.** Ссылка на релиз и строка для потребителя: `.package(url: "https://github.com/maldrakar/westron", from: "<версия>")`.

Никогда не публикуй без подтверждения в шаге 6 и не переписывай уже выпущенные теги.
