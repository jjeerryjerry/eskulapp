import puppeteer from 'puppeteer';
import fs from 'node:fs';
import path from 'node:path';

const SRC = '/home/jjeerry/agents/eskulapp/design/faza-a';
const OUT = '/home/jjeerry/agents/eskulapp/tools/shots/out';
fs.mkdirSync(OUT, { recursive: true });

// kolejnosc + ladne nazwy
const screens = [
  ['App-Wejscie', '01-Wejscie-kodem'],
  ['App-Eventy', '02-Moje-wydarzenia'],
  ['App-Event', '03-Ekran-eventu'],
  ['App-Agenda', '04-Agenda'],
  ['App-Aktualnosci', '05-Aktualnosci'],
  ['App-Prelekcja', '06-Prelekcja'],
  ['App-Prelegenci', '07-Prelegenci'],
  ['App-Partnerzy', '08-Partnerzy'],
  ['App-Mapa', '09-Mapa'],
  ['App-Kontakt', '10-Kontakt'],
  ['App-Offline', '11-Tryb-offline'],
  ['App-Pusty', '12-Stan-pusty'],
];

function standalone(dc) {
  // <style> z helmet
  const style = (dc.match(/<style>([\s\S]*?)<\/style>/) || [,''])[1];
  // tresc miedzy </helmet> a </x-dc>
  let body = (dc.match(/<\/helmet>([\s\S]*?)<\/x-dc>/) || [,''])[1].trim();
  return `<!doctype html><html><head><meta charset="utf-8">
<style>${style}</style></head><body>${body}</body></html>`;
}

const browser = await puppeteer.launch({
  args: ['--no-sandbox', '--disable-setuid-sandbox', '--font-render-hinting=none'],
});
const page = await browser.newPage();
await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2 });

for (const [file, name] of screens) {
  const dc = fs.readFileSync(path.join(SRC, file + '.dc.html'), 'utf8');
  await page.setContent(standalone(dc), { waitUntil: 'load' });
  await new Promise(r => setTimeout(r, 250));
  const out = path.join(OUT, name + '.png');
  await page.screenshot({ path: out, clip: { x: 0, y: 0, width: 390, height: 844 } });
  console.log('render', name + '.png');
}
await browser.close();
console.log('DONE', screens.length, 'PNG ->', OUT);
