import assert from "node:assert/strict";
import { test } from "node:test";

import { collect, findDrift, type Generator } from "./generate.ts";

const fake = (name: string, files: Record<string, string>): Generator => ({
  name,
  run: () => new Map(Object.entries(files)),
});

test("собирает выходы всех генераторов", async () => {
  const outputs = await collect([fake("a", { "x.swift": "1" }), fake("b", { "y.css": "2" })]);
  assert.deepEqual([...outputs], [["x.swift", "1"], ["y.css", "2"]]);
});

test("два генератора не могут выпускать один файл", async () => {
  await assert.rejects(collect([fake("a", { "x.swift": "1" }), fake("b", { "x.swift": "2" })]), /x\.swift/);
});

test("находит отсутствующие и изменённые файлы", () => {
  const disk: Record<string, string> = { "same.swift": "1", "changed.swift": "old" };
  const outputs = new Map([
    ["same.swift", "1"],
    ["changed.swift", "new"],
    ["missing.swift", "3"],
  ]);
  assert.deepEqual(
    findDrift(outputs, (path) => disk[path]),
    [
      { path: "changed.swift", reason: "отличается" },
      { path: "missing.swift", reason: "отсутствует" },
    ],
  );
});
