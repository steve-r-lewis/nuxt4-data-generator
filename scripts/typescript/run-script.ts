#!/usr/bin/env ts-node

/**
 * ================================================================================
 *
 * @project:    uuidv7-generator
 * @file:       ~/scripts/typescript/run-script.ts
 * @version:    V1.0.0
 * @createDate: 2025 Dec 05
 * @createTime: 22:17
 * @author:     Steve R Lewis
 *
 * ================================================================================
 *
 * @description:
 * Universal Cross-Platform Wrapper for PowerShell scripts.
 *
 * Usage:
 * node ./scripts/typescript/run-script.ts <ScriptName> [Flags]
 *
 * Examples:
 * node run-script.ts nuxtManager -Debug
 * node run-script.ts gitInitialise -Log
 *
 * ================================================================================
 *
 * @notes: Revision History
 *
 * V1.0.0, 20251205-22:17
 * Initial creation and release of run-script.ts
 *
 * ================================================================================
 */

import { spawnSync } from "child_process";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

// Fix __dirname for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 1. Parse Arguments
// argv[0]=node, argv[1]=wrapper.ts, argv[2]=ScriptName, argv[3+]=Flags
const scriptName = process.argv[2];
const scriptArgs = process.argv.slice(3);

if (!scriptName) {
  console.error("[ERROR] No script name provided.");
  console.error("Usage: node run-script.ts <ScriptName> [flags]");
  process.exit(1);
}

// Ensure extension (optional convenience)
const targetFile = scriptName.endsWith(".ps1") ? scriptName : `${scriptName}.ps1`;

// 2. Path Resolution Logic
// Search priority:
// 1. ../powershell/ (Standard)
// 2. ../../powershell/scripts/ (Legacy/Fallback)
const searchPaths = [
  path.resolve(__dirname, "../powershell"),
  path.resolve(__dirname, "../../scripts/powershell"),
  path.resolve(__dirname, "../../powershell/scripts")
];

let scriptPath = "";
for (const searchDir of searchPaths) {
  const potentialPath = path.join(searchDir, targetFile);
  if (fs.existsSync(potentialPath)) {
    scriptPath = potentialPath;
    break;
  }
}

// Final Check
if (!scriptPath) {
  console.error(`\n[ERROR] Script '${targetFile}' not found!`);
  console.error("Searched in:");
  searchPaths.forEach(p => console.error(` - ${p}`));
  process.exit(1);
}

// 3. Execution Logic
const isWin = process.platform === "win32";
const pwshArgs = ["-NoProfile"];

if (isWin) {
  pwshArgs.push("-ExecutionPolicy", "Bypass");
}

pwshArgs.push("-File", scriptPath);
pwshArgs.push(...scriptArgs);

// Spawn Child Process
const result = spawnSync("pwsh", pwshArgs, { stdio: "inherit" });

if (result.error) {
  console.error("Error executing PowerShell script:", result.error);
  process.exit(1);
}

process.exit(result.status ?? 1);


