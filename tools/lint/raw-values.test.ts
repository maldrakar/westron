import assert from "node:assert/strict";
import { test } from "node:test";

import { findRawValues } from "./raw-values.ts";

const kinds = (source: string) => findRawValues(source).map((v) => `${v.line}:${v.kind}:${v.text}`);

test("находит сырые цвета", () => {
  assert.deepEqual(
    kinds(
      [
        "let a = Color(red: 0.2, green: 0.3, blue: 0.4)",
        "let b = Color(.sRGB, red: 1, green: 1, blue: 1)",
        'let c = Color(hex: "#3653C9")',
        "let d = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)",
        "let e = NSColor(white: 0.5, alpha: 1)",
      ].join("\n"),
    ),
    [
      "1:цвет:Color(red:",
      "2:цвет:Color(.sRGB,",
      "3:цвет:Color(hex:",
      '3:цвет:"#3653C9"',
      "4:цвет:#colorLiteral(",
      "5:цвет:NSColor(white:",
    ],
  );
});

test("находит сырые размеры, отступы, прозрачность и анимацию", () => {
  assert.deepEqual(
    kinds(
      [
        ".padding(12)",
        ".padding(.horizontal, 8)",
        ".frame(width: 44, height: 44)",
        "VStack(spacing: 6) {",
        "RoundedRectangle(cornerRadius: 10)",
        ".font(.system(size: 17))",
        ".opacity(0.4)",
        ".animation(.easeInOut(duration: 0.25), value: x)",
        ".spring(response: 0.3, dampingFraction: 0.8)",
      ].join("\n"),
    ),
    [
      "1:размер или отступ:.padding(12)",
      "2:размер или отступ:.padding(.horizontal, 8)",
      "3:размер или отступ:width: 44",
      "3:размер или отступ:height: 44",
      "4:размер или отступ:spacing: 6",
      "5:размер или отступ:cornerRadius: 10",
      "6:шрифт:size: 17",
      "7:прозрачность или масштаб:.opacity(0.4)",
      "8:анимация:duration: 0.25",
      "9:анимация:response: 0.3",
      "9:анимация:dampingFraction: 0.8",
    ],
  );
});

test("пропускает токены, нули, единицы и не числа", () => {
  assert.deepEqual(
    kinds(
      [
        ".padding(Spacing.m)",
        ".padding(0)",
        "VStack(spacing: 0) {",
        ".frame(maxWidth: .infinity)",
        ".opacity(1)",
        ".opacity(isEnabled ? 1 : Opacity.disabled)",
        ".foregroundStyle(Color.accentColor)",
        "let size: CGFloat = metrics.size",
      ].join("\n"),
    ),
    [],
  );
});

test("пропускает комментарии и строки с исключением", () => {
  assert.deepEqual(
    kinds(
      [
        "// .padding(12) в комментарии",
        "/* Color(red: 1, green: 0, blue: 0) */",
        "/*",
        "  .opacity(0.5)",
        "*/",
        ".padding(4) // westron-lint: allow оптическая компенсация иконки",
        "// westron-lint: allow фиксированный размер системной иконки",
        ".frame(width: 20)",
        ".frame(height: 30)",
      ].join("\n"),
    ),
    ["9:размер или отступ:height: 30"],
  );
});
