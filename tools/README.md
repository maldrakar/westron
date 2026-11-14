# Инструменты

| Путь | Что делает |
|---|---|
| `apple/xcode-env.sh` | Находит Xcode из `.xcode-version` и выставляет `DEVELOPER_DIR` |
| `apple/check.sh` | Сборка, тесты, формат и сборка каталога для Apple; их же запускают CI и хук Stop |
| `apple/catalog-screenshot.sh` | Скриншот записи каталога на iOS или macOS |
| `lint/raw-values.ts` | Линт «никаких сырых значений» для `WestronUI` |
| `generate/generate.ts` | Реестр генераторов; `--check` сверяет закоммиченный код со свежей генерацией |

TypeScript запускается Node 24 без сборки: `npm test`, `npm run typecheck`, `npm run generate`.
