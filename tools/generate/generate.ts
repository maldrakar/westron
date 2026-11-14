// The single entry point for the westron generators.
//
//   node tools/generate/generate.ts           write the generated files
//   node tools/generate/generate.ts --check   compare the files on disk with a fresh generation, writing nothing
//
// Generated code is committed (decisions/0001), and CI runs --check: a mismatch means
// that someone changed the source but did not rerun generation, or edited a generated file by hand.
// Every generator is deterministic: for the same input it produces the same bytes.

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

export interface Generator {
  /** A short name for the output, for example `tokens-apple`. */
  name: string;
  /** Paths relative to the repository root → file contents. */
  run(): Promise<Map<string, string>> | Map<string, string>;
}

/**
 * The generator registry. Empty for now: the first generators are tokens for Apple (phase 1, #13, #14)
 * and the API from the contracts (phase 2, #20).
 */
export const generators: Generator[] = [];

export interface Drift {
  path: string;
  reason: "missing" | "differs";
}

export async function collect(list: Generator[]): Promise<Map<string, string>> {
  const outputs = new Map<string, string>();
  for (const generator of list) {
    for (const [path, content] of await generator.run()) {
      if (outputs.has(path)) throw new Error(`${generator.name}: file ${path} is already produced by another generator`);
      outputs.set(path, content);
    }
  }
  return outputs;
}

export function findDrift(outputs: Map<string, string>, read: (path: string) => string | undefined): Drift[] {
  const drift: Drift[] = [];
  for (const [path, content] of outputs) {
    const current = read(path);
    if (current === undefined) drift.push({ path, reason: "missing" });
    else if (current !== content) drift.push({ path, reason: "differs" });
  }
  return drift;
}

async function main(args: string[]): Promise<number> {
  const check = args.includes("--check");
  if (generators.length === 0) {
    console.log("generate: no generators yet; they arrive in phase 1");
    return 0;
  }
  const outputs = await collect(generators);
  if (check) {
    const drift = findDrift(outputs, (path) => (existsSync(path) ? readFileSync(path, "utf8") : undefined));
    for (const d of drift) console.error(`${d.path}: ${d.reason} (compared with a fresh generation)`);
    if (drift.length > 0) {
      console.error("generate --check: run `npm run generate` and commit the result");
      return 1;
    }
    console.log(`generate --check: files: ${outputs.size}, all match`);
    return 0;
  }
  for (const [path, content] of outputs) {
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, content);
  }
  console.log(`generate: files written: ${outputs.size}`);
  return 0;
}

if (import.meta.main) process.exitCode = await main(process.argv.slice(2));
