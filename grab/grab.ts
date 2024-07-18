import { chromium, devices } from 'playwright';
import assert from 'node:assert';

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();

  const arg = process.argv[2];
  let edition = arg;

  if (arg === "version") {
	edition = "photo";
  }

  await page.goto(`https://store.serif.com/en-gb/update/windows/${edition}/2/`);

  const span = await page.locator("a", {has: page.locator('span:has-text("MSI/EXE (x64) ")')});
  const link = await span.getAttribute("href");

  await browser.close();

  if (arg === "version" && link) {
	const regex = /\d+\.\d+\.\d+/;
	const match = link.match(regex);

	if (!match) return;

	console.log(`"${match[0]}"`);

	return;
  }

  console.log(link);
})();
