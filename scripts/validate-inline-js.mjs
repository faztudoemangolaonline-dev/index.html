import fs from "node:fs/promises";
import vm from "node:vm";

const files = ["index.html", "musica-angolana.html"];
let checked = 0;
for (const file of files) {
  const html = await fs.readFile(file, "utf8");
  const blocks = [...html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)];
  for (let i = 0; i < blocks.length; i++) {
    const attrs = blocks[i][1] || "";
    const source = blocks[i][2] || "";
    if (/\bsrc\s*=|application\/ld\+json|type\s*=\s*["']module["']/i.test(attrs) || !source.trim()) continue;
    new vm.Script(source, { filename: file + ":inline-script-" + (i + 1) });
    checked++;
  }
}
console.log("JavaScript inline validado: " + checked + " bloco(s).");
