import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const root = process.env.GITHUB_WORKSPACE || process.cwd();
const names = (await fs.readdir(root)).filter(name => /^image-assets-[0-9]+[.]json$/.test(name)).sort();
let totalOriginal = 0;
let totalOptimized = 0;
let converted = 0;

for (const name of names) {
  const sourcePath = path.join(root, name);
  const sourceText = await fs.readFile(sourcePath, "utf8");
  const source = JSON.parse(sourceText);
  const output = {};
  for (const [key, value] of Object.entries(source)) {
    if (typeof value === "string" && value.startsWith("data:image/")) {
      const comma = value.indexOf(",");
      const input = Buffer.from(value.slice(comma + 1), "base64");
      totalOriginal += input.length;
      try {
        const result = await sharp(input, { failOn: "none" })
          .rotate()
          .resize({ width: 1280, height: 1280, fit: "inside", withoutEnlargement: true })
          .webp({ quality: 82, effort: 6, smartSubsample: true })
          .toBuffer();
        if (result.length < input.length) {
          output[key] = "data:image/webp;base64," + result.toString("base64");
          totalOptimized += result.length;
          converted++;
        } else {
          output[key] = value;
          totalOptimized += input.length;
        }
      } catch {
        output[key] = value;
        totalOptimized += input.length;
      }
    } else {
      output[key] = value;
    }
  }
  const match = name.match(/^image-assets-([0-9]+)[.]json$/);
  const outputName = "image-assets-webp-" + match[1] + ".json";
  await fs.writeFile(path.join(root, outputName), JSON.stringify(output));
  console.log(name + " -> " + outputName);
}
console.log(JSON.stringify({
  chunks: names.length,
  convertedImages: converted,
  originalImageBytes: totalOriginal,
  optimizedImageBytes: totalOptimized,
  reductionPercent: totalOriginal ? Number((100 * (1 - totalOptimized / totalOriginal)).toFixed(1)) : 0
}, null, 2));
