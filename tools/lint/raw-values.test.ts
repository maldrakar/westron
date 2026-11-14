import assert from "node:assert/strict";
import { test } from "node:test";

import { findRawValues } from "./raw-values.ts";

const kinds = (source: string) => findRawValues(source).map((v) => `${v.line}:${v.kind}:${v.text}`);

test("finds raw colors", () => {
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
      "1:color:Color(red:",
      "2:color:Color(.sRGB,",
      "3:color:Color(hex:",
      '3:color:"#3653C9"',
      "4:color:#colorLiteral(",
      "5:color:NSColor(white:",
    ],
  );
});

test("finds raw sizes, spacing, opacity and animation", () => {
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
      "1:size or spacing:.padding(12)",
      "2:size or spacing:.padding(.horizontal, 8)",
      "3:size or spacing:width: 44",
      "3:size or spacing:height: 44",
      "4:size or spacing:spacing: 6",
      "5:size or spacing:cornerRadius: 10",
      "6:font:size: 17",
      "7:opacity or scale:.opacity(0.4)",
      "8:animation:duration: 0.25",
      "9:animation:response: 0.3",
      "9:animation:dampingFraction: 0.8",
    ],
  );
});

test("finds padding with an edge set, EdgeInsets, line spacing and CGFloat constants", () => {
  assert.deepEqual(
    kinds(
      [
        ".padding([.top, .bottom], 12)",
        "EdgeInsets(top: 12, leading: 0, bottom: 8, trailing: 16)",
        ".lineSpacing(4)",
        ".tracking(0.5)",
        "let inset: CGFloat = 12",
        "let gap = CGFloat(6)",
      ].join("\n"),
    ),
    [
      "1:size or spacing:.padding([.top, .bottom], 12)",
      "2:size or spacing:top: 12",
      "2:size or spacing:bottom: 8",
      "2:size or spacing:trailing: 16",
      "3:font:.lineSpacing(4)",
      "4:font:.tracking(0.5)",
      "5:size or spacing:CGFloat = 12",
      "6:size or spacing:CGFloat(6)",
    ],
  );
});

test("skips tokens, zeros, ones and non-numbers", () => {
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

test("skips comments and lines with an exception", () => {
  assert.deepEqual(
    kinds(
      [
        "// .padding(12) in a comment",
        "/* Color(red: 1, green: 0, blue: 0) */",
        "/*",
        "  .opacity(0.5)",
        "*/",
        ".padding(4) // westron-lint: allow optical compensation for the icon",
        "// westron-lint: allow fixed size of a system icon",
        ".frame(width: 20)",
        ".frame(height: 30)",
      ].join("\n"),
    ),
    ["9:size or spacing:height: 30"],
  );
});
