// Единая точка запуска генераторов westron.
//
//   node tools/generate/generate.ts           записать сгенерированные файлы
//   node tools/generate/generate.ts --check   сравнить файлы на диске со свежей генерацией, ничего не записывая
//
// Сгенерированный код коммитится (decisions/0001), а CI запускает --check: расхождение означает,
// что источник поменяли, а генерацию не перезапустили, или что сгенерированный файл правили руками.
// Каждый генератор детерминирован: на том же входе выдаёт те же байты.

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

export interface Generator {
  /** Короткое имя для вывода, например `tokens-apple`. */
  name: string;
  /** Пути относительно корня репозитория → содержимое файлов. */
  run(): Promise<Map<string, string>> | Map<string, string>;
}

/**
 * Реестр генераторов. Пока пуст: первые генераторы — токены для Apple (фаза 1, #13, #14)
 * и API из контрактов (фаза 2, #20).
 */
export const generators: Generator[] = [];

export interface Drift {
  path: string;
  reason: "отсутствует" | "отличается";
}

export async function collect(list: Generator[]): Promise<Map<string, string>> {
  const outputs = new Map<string, string>();
  for (const generator of list) {
    for (const [path, content] of await generator.run()) {
      if (outputs.has(path)) throw new Error(`${generator.name}: файл ${path} уже выпускает другой генератор`);
      outputs.set(path, content);
    }
  }
  return outputs;
}

export function findDrift(outputs: Map<string, string>, read: (path: string) => string | undefined): Drift[] {
  const drift: Drift[] = [];
  for (const [path, content] of outputs) {
    const current = read(path);
    if (current === undefined) drift.push({ path, reason: "отсутствует" });
    else if (current !== content) drift.push({ path, reason: "отличается" });
  }
  return drift;
}

async function main(args: string[]): Promise<number> {
  const check = args.includes("--check");
  if (generators.length === 0) {
    console.log("generate: генераторов пока нет — появятся в фазе 1");
    return 0;
  }
  const outputs = await collect(generators);
  if (check) {
    const drift = findDrift(outputs, (path) => (existsSync(path) ? readFileSync(path, "utf8") : undefined));
    for (const d of drift) console.error(`${d.path}: ${d.reason} от свежей генерации`);
    if (drift.length > 0) {
      console.error("generate --check: запустите `npm run generate` и закоммитьте результат");
      return 1;
    }
    console.log(`generate --check: файлов — ${outputs.size}, все совпадают`);
    return 0;
  }
  for (const [path, content] of outputs) {
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, content);
  }
  console.log(`generate: файлов записано — ${outputs.size}`);
  return 0;
}

if (import.meta.main) process.exitCode = await main(process.argv.slice(2));
