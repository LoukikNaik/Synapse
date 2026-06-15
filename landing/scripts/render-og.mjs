// Render the OG image to public/og.png.
//
// Usage:   node scripts/render-og.mjs [output-path]
// Default: public/og.png
//
// Requires playwright + a Chromium browser available locally:
//   npm i -D playwright && npx playwright install chromium

import { chromium } from "playwright";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const source = path.resolve(__dirname, "og.html");
const out = path.resolve(
  __dirname,
  "..",
  process.argv[2] || "public/og.png",
);

const browser = await chromium.launch({ headless: true });
const ctx = await browser.newContext({
  viewport: { width: 1200, height: 800 },
  deviceScaleFactor: 2,
});
const page = await ctx.newPage();
await page.goto(`file://${source}`, { waitUntil: "networkidle" });
await page.waitForTimeout(800);
await page.screenshot({
  path: out,
  type: "png",
  clip: { x: 0, y: 0, width: 1200, height: 800 },
});
await browser.close();
console.log(`rendered ${out}`);
