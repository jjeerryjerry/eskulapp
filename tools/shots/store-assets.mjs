import puppeteer from 'puppeteer';
import fs from 'node:fs';
import path from 'node:path';

const SHOTS = '/home/jjeerry/agents/eskulapp/tools/shots/out';
const OUT = '/home/jjeerry/agents/eskulapp/tools/shots/store';
fs.mkdirSync(OUT, { recursive: true });

const PETROL = '#0C5A63';
const PETROL_DK = '#08363B';
const CORAL = '#FF6B57';

// Znak marki (laska + waz w ksztalcie E), viewBox 40x48
const MARK = (staff, snake) => `<svg viewBox="0 0 40 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="9" y="7" width="6" height="34" rx="3" fill="${staff}"/>
  <path d="M31 9 L18 9 L18 39 L31 39" stroke="${snake}" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M18 24 L28 24" stroke="${snake}" stroke-width="6" fill="none" stroke-linecap="round"/>
  <circle cx="31" cy="9" r="3.2" fill="${snake}"/></svg>`;

const browser = await puppeteer.launch({
  args: ['--no-sandbox', '--disable-setuid-sandbox', '--font-render-hinting=none'],
});
const page = await browser.newPage();

async function shot(html, w, h, out) {
  await page.setViewport({ width: w, height: h, deviceScaleFactor: 1 });
  await page.setContent(html, { waitUntil: 'load' });
  await new Promise(r => setTimeout(r, 120));
  await page.screenshot({ path: out, clip: { x: 0, y: 0, width: w, height: h } });
  console.log('->', path.basename(out), w + 'x' + h);
}

// 1) Ikona sklepu 512x512 (Google i tak maskuje rogi; full-bleed petrol)
await shot(`<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;padding:0}
  .icon{width:512px;height:512px;display:flex;align-items:center;justify-content:center;
        background:radial-gradient(120% 120% at 30% 20%, #0F6E78 0%, ${PETROL} 55%, ${PETROL_DK} 100%);}
  .icon svg{width:300px;height:auto;filter:drop-shadow(0 10px 24px rgba(0,0,0,.28));}
</style></head><body><div class="icon">${MARK('#fff', CORAL)}</div></body></html>`,
  512, 512, path.join(OUT, 'icon-512.png'));

// 2) Feature graphic 1024x500
await shot(`<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;padding:0}
  .fg{width:1024px;height:500px;box-sizing:border-box;padding:0 72px;display:flex;align-items:center;gap:44px;
      background:radial-gradient(90% 140% at 12% 20%, #0F6E78 0%, ${PETROL} 52%, ${PETROL_DK} 100%);
      font-family:'Sora',system-ui,-apple-system,Segoe UI,Roboto,sans-serif;color:#fff;}
  .seal{width:190px;height:190px;flex:none;border-radius:44px;display:flex;align-items:center;justify-content:center;
        background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.18);}
  .seal svg{width:120px;height:auto}
  .word{font-size:76px;font-weight:800;letter-spacing:-1.5px;line-height:1;}
  .word b{color:#BFE9EC;font-weight:800}
  .tag{margin-top:16px;font-size:27px;font-weight:500;color:#DCEDEF;max-width:560px;line-height:1.28}
  .dot{color:${CORAL}}
</style></head><body>
  <div class="fg">
    <div class="seal">${MARK('#fff', CORAL)}</div>
    <div>
      <div class="word">Eskul<b>app</b></div>
      <div class="tag">Twoj przewodnik po konferencji medycznej<span class="dot">.</span> Agenda, prelegenci, mapa i partnerzy w jednym miejscu.</div>
    </div>
  </div></body></html>`,
  1024, 500, path.join(OUT, 'feature-1024x500.png'));

// 3) Zrzuty na petrolowym tle -> 1080x1920 (proporcja 1.78, w limicie 2:1)
const shotFiles = fs.readdirSync(SHOTS).filter(f => f.endsWith('.png')).sort();
for (const f of shotFiles) {
  const b64 = fs.readFileSync(path.join(SHOTS, f)).toString('base64');
  await shot(`<!doctype html><html><head><meta charset="utf-8"><style>
    html,body{margin:0;padding:0}
    .stage{width:1080px;height:1920px;display:flex;align-items:center;justify-content:center;
      background:linear-gradient(160deg, #0F6E78 0%, ${PETROL} 55%, ${PETROL_DK} 100%);}
    .frame{border-radius:34px;overflow:hidden;box-shadow:0 30px 70px rgba(0,0,0,.35);
      border:6px solid rgba(255,255,255,.10);}
    .frame img{display:block;height:1720px;width:auto;}
  </style></head><body>
    <div class="stage"><div class="frame"><img src="data:image/png;base64,${b64}"></div></div>
  </body></html>`,
  1080, 1920, path.join(OUT, 'shot-' + f));
}

await browser.close();
console.log('DONE ->', OUT);
