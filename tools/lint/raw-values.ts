// The "no raw values" lint: in westron component code, colors, sizes, spacing, radii,
// opacity and animation come only from tokens (decisions/0005).
//
//   node tools/lint/raw-values.ts [file.swift …]
//
// Without arguments it checks every .swift file in platforms/apple/Sources/WestronUI. Exit code 1 if there are
// violations. An exception for a line: a `// westron-lint: allow <reason>` comment on it or on the line above.

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
  /** Allowed numbers: if the first non-empty capture group is one of them, the match is skipped. */
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
  "top",
  "leading",
  "bottom",
  "trailing",
  "x",
  "y",
].join("|");
const motionLabels = ["duration", "response", "dampingFraction", "bounce", "blendDuration", "delay"].join("|");

const rules: Rule[] = [
  {
    kind: "color",
    pattern: /\b(?:Color|UIColor|NSColor)\(\s*(?:red|hue|white|\.sRGB|\.displayP3|hex)\s*[:,]|#colorLiteral\(/g,
  },
  { kind: "color", pattern: /"#[0-9a-fA-F]{3,8}"/g },
  { kind: "font", pattern: new RegExp(String.raw`\bsize:\s*${number}`, "g") },
  {
    kind: "font",
    pattern: new RegExp(String.raw`\.(?:lineSpacing|tracking|kerning)\(\s*${number}\s*\)`, "g"),
    allowed: [0],
  },
  {
    kind: "size or spacing",
    pattern: new RegExp(String.raw`\bCGFloat\s*(?:=\s*${number}|\(\s*${number}\s*\))`, "g"),
    allowed: [0],
  },
  {
    kind: "size or spacing",
    pattern: new RegExp(String.raw`\b(?:${layoutLabels}):\s*${number}`, "g"),
    allowed: [0],
  },
  {
    kind: "size or spacing",
    pattern: new RegExp(
      String.raw`\.(?:padding|cornerRadius)\(\s*(?:(?:\.\w+|\[[^\]]*\])\s*,\s*)?${number}\s*\)`,
      "g",
    ),
    allowed: [0],
  },
  {
    kind: "opacity or scale",
    pattern: new RegExp(String.raw`\.(?:opacity|scaleEffect)\(\s*${number}\s*\)`, "g"),
    allowed: [0, 1],
  },
  {
    kind: "animation",
    pattern: new RegExp(String.raw`\b(?:${motionLabels}):\s*${number}`, "g"),
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
        const captured = match.slice(1).find((group) => group !== undefined);
        if (captured !== undefined && (rule.allowed ?? []).includes(Number(captured))) continue;
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
        `${relative(process.cwd(), file)}:${v.line}:${v.column}: raw value (${v.kind}) \`${v.text}\`: ` +
          `use a token; for a deliberate exception: // ${allowMarker} <reason>`,
      );
    }
  }
  if (count > 0) {
    console.error(`raw-values: violations: ${count}`);
    return 1;
  }
  console.log(`raw-values: files checked: ${files.length}, no violations`);
  return 0;
}

if (import.meta.main) process.exitCode = main(process.argv.slice(2));
