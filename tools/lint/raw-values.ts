// Линт «никаких сырых значений»: в коде компонентов westron цвета, размеры, отступы, радиусы,
// прозрачность и анимация берутся только из токенов (decisions/0005).
//
//   node tools/lint/raw-values.ts [файл.swift …]
//
// Без аргументов проверяет все .swift в platforms/apple/Sources/WestronUI. Код выхода 1, если есть нарушения.
// Исключение для строки: комментарий `// westron-lint: allow <причина>` на ней или строкой выше.

import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";

export interface Violation {
  line: number;
  column: number;
  text: string;
  kind: string;
}

interface Rule {
  kind: string;
  pattern: RegExp;
  /** Индекс группы с числом; если число разрешено, совпадение пропускается. */
  numberGroup?: number;
  allowed?: number[];
}

const number = String.raw`(-?\d+(?:\.\d+)?)`;
const layoutLabels = [
  "spacing",
  "cornerRadius",
  "radius",
  "lineWidth",
  "width",
  "height",
  "minWidth",
  "idealWidth",
  "maxWidth",
  "minHeight",
  "idealHeight",
  "maxHeight",
  "minLength",
  "x",
  "y",
].join("|");
const motionLabels = ["duration", "response", "dampingFraction", "bounce", "blendDuration", "delay"].join("|");

const rules: Rule[] = [
  {
    kind: "цвет",
    pattern: /\b(?:Color|UIColor|NSColor)\(\s*(?:red|hue|white|\.sRGB|\.displayP3|hex)\s*[:,]|#colorLiteral\(/g,
  },
  { kind: "цвет", pattern: /"#[0-9a-fA-F]{3,8}"/g },
  { kind: "шрифт", pattern: new RegExp(String.raw`\bsize:\s*${number}`, "g"), numberGroup: 1 },
  {
    kind: "размер или отступ",
    pattern: new RegExp(String.raw`\b(?:${layoutLabels}):\s*${number}`, "g"),
    numberGroup: 1,
    allowed: [0],
  },
  {
    kind: "размер или отступ",
    pattern: new RegExp(String.raw`\.(?:padding|cornerRadius)\(\s*(?:\.\w+\s*,\s*)?${number}\s*\)`, "g"),
    numberGroup: 1,
    allowed: [0],
  },
  {
    kind: "прозрачность или масштаб",
    pattern: new RegExp(String.raw`\.(?:opacity|scaleEffect)\(\s*${number}\s*\)`, "g"),
    numberGroup: 1,
    allowed: [0, 1],
  },
  {
    kind: "анимация",
    pattern: new RegExp(String.raw`\b(?:${motionLabels}):\s*${number}`, "g"),
    numberGroup: 1,
    allowed: [0],
  },
];

const allowMarker = "westron-lint: allow";

export function findRawValues(source: string): Violation[] {
  const lines = source.split("\n");
  const violations: Violation[] = [];
  let inBlockComment = false;
  lines.forEach((rawLine, index) => {
    let line = rawLine;
    if (inBlockComment) {
      const end = line.indexOf("*/");
      if (end === -1) return;
      line = " ".repeat(end + 2) + line.slice(end + 2);
      inBlockComment = false;
    }
    line = line.replace(/\/\*.*?\*\//g, (m) => " ".repeat(m.length));
    const blockStart = line.indexOf("/*");
    if (blockStart !== -1) {
      inBlockComment = true;
      line = line.slice(0, blockStart);
    }
    const commentStart = line.indexOf("//");
    if (commentStart !== -1) line = line.slice(0, commentStart);

    const previous = index > 0 ? lines[index - 1] : "";
    if (rawLine.includes(allowMarker) || (previous?.trim().startsWith("//") && previous.includes(allowMarker))) return;

    for (const rule of rules) {
      for (const match of line.matchAll(rule.pattern)) {
        if (rule.numberGroup !== undefined) {
          const value = Number(match[rule.numberGroup]);
          if ((rule.allowed ?? []).includes(value)) continue;
        }
        violations.push({ line: index + 1, column: (match.index ?? 0) + 1, text: match[0], kind: rule.kind });
      }
    }
  });
  return violations.sort((a, b) => a.line - b.line || a.column - b.column);
}

function swiftFiles(path: string): string[] {
  if (!statSync(path).isDirectory()) return path.endsWith(".swift") ? [path] : [];
  return readdirSync(path, { withFileTypes: true }).flatMap((entry) => swiftFiles(join(path, entry.name)));
}

export const defaultRoots = ["platforms/apple/Sources/WestronUI"];

function main(args: string[]): number {
  const files = (args.length > 0 ? args : defaultRoots).flatMap(swiftFiles);
  let count = 0;
  for (const file of files) {
    for (const v of findRawValues(readFileSync(file, "utf8"))) {
      count += 1;
      console.error(
        `${relative(process.cwd(), file)}:${v.line}:${v.column}: сырое значение (${v.kind}) «${v.text}» — ` +
          `возьмите токен; осознанное исключение: // ${allowMarker} <причина>`,
      );
    }
  }
  if (count > 0) {
    console.error(`raw-values: нарушений — ${count}`);
    return 1;
  }
  console.log(`raw-values: файлов проверено — ${files.length}, нарушений нет`);
  return 0;
}

if (import.meta.main) process.exitCode = main(process.argv.slice(2));
