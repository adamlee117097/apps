// Draws look-and-feel mock-ups for Necromancer Tactics as SVG and saves them as PNG.
// These are code-drawn placeholders, not final art. Run: node render.js <output directory>
const { chromium } = require('playwright');
const path = require('path');

const C = {
  ink: '#121018', panel: '#1b1823', panel2: '#242030', line: '#3a3548', text: '#e9e4d6', dim: '#9b94a8',
  ground: '#2b2934', ground2: '#302e3a', rough: '#22342b', roughMark: '#3d6b4f', wall: '#4b4758', wallTop: '#625d73',
  water: '#1b3447', waterMark: '#2f5d7a',
  player: '#4fe0a3', enemy: '#f0b54a', bone: '#e9e3cf', flesh: '#c97a86', spirit: '#9fb6f2',
  steel: '#b8c0cc', flame: '#f08a4b', holy: '#f6e39a', sovereign: '#b48cf0',
  holyGlow: '#f6e39a', threat: '#e2525c', move: '#4fe0a3', corpse: '#8d8798',
};
const SERIF = "Georgia, 'DejaVu Serif', serif";
const SANS = "'DejaVu Sans', Verdana, sans-serif";

const UNITS = {
  overlord: { type: 'sovereign', name: 'Overlord' }, skeleton: { type: 'bone', name: 'Skeleton' },
  bone_archer: { type: 'bone', name: 'Bone Archer' }, ghoul: { type: 'flesh', name: 'Ghoul' },
  shade: { type: 'spirit', name: 'Shade' }, militia: { type: 'steel', name: 'Militia' },
  archer: { type: 'steel', name: 'Archer' }, knight: { type: 'steel', name: 'Knight' },
  pyromancer: { type: 'flame', name: 'Pyromancer' }, cleric: { type: 'holy', name: 'Cleric' },
};

// The battle shown in every mock-up: mid-fight, with a pile of bodies on consecrated ground.
const ROWS = [
  '................', '..ff.......##...', '..f.........#...', '................',
  '.....ff.........', '......f.........', '................', '.....f..........',
  '....ff......#...', '......~~...##...', '..f...~~........', '................',
];
const PIECES = [
  { k: 'overlord', s: 'p', x: 4, y: 6, hp: 1 }, { k: 'skeleton', s: 'p', x: 7, y: 4, hp: 0.6 },
  { k: 'skeleton', s: 'p', x: 8, y: 7, hp: 1 }, { k: 'bone_archer', s: 'p', x: 6, y: 6, hp: 1 },
  { k: 'ghoul', s: 'p', x: 10, y: 7, hp: 0.77, selected: true },
  { k: 'militia', s: 'e', x: 8, y: 3, hp: 0.5 }, { k: 'militia', s: 'e', x: 12, y: 7, hp: 1 },
  { k: 'knight', s: 'e', x: 11, y: 5, hp: 1 }, { k: 'archer', s: 'e', x: 12, y: 3, hp: 1 },
  { k: 'pyromancer', s: 'e', x: 13, y: 6, hp: 1 }, { k: 'cleric', s: 'e', x: 10, y: 6, hp: 1, target: true },
];
const CORPSES = [{ x: 6, y: 3, n: 1 }, { x: 7, y: 8, n: 1 }, { x: 9, y: 5, n: 2 }];
const BLESSED = [[9, 5], [8, 5], [10, 5], [9, 4], [9, 6]];

const has = (list, x, y) => list.some(p => p[0] === x && p[1] === y);

function shape(type, cx, cy, r) {
  const pts = a => a.map(([dx, dy]) => `${(cx + dx * r).toFixed(1)},${(cy + dy * r).toFixed(1)}`).join(' ');
  switch (type) {
    case 'bone': return `<polygon points="${pts([[0, -1.08], [1.08, 0], [0, 1.08], [-1.08, 0]])}"`;
    case 'flesh': return `<circle cx="${cx}" cy="${cy}" r="${r * 0.95}"`;
    case 'spirit': return `<polygon points="${pts([[-1, -0.8], [1, -0.8], [0, 1.1]])}"`;
    case 'steel': return `<rect x="${cx - r * 0.86}" y="${cy - r * 0.86}" width="${r * 1.72}" height="${r * 1.72}" rx="${r * 0.14}"`;
    case 'flame': return `<polygon points="${pts([[0, -1.1], [1, 0.8], [-1, 0.8]])}"`;
    case 'holy': return `<polygon points="${pts([[-0.5, -0.95], [0.5, -0.95], [1.05, 0], [0.5, 0.95], [-0.5, 0.95], [-1.05, 0]])}"`;
    default: return `<polygon points="${pts([[0, -1.1], [0.42, -0.42], [1.1, 0], [0.42, 0.42], [0, 1.1], [-0.42, 0.42], [-1.1, 0], [-0.42, -0.42]])}"`;
  }
}

function glyph(kind, cx, cy, r, col) {
  const s = r / 10, t = (x, y) => `${(cx + x * s).toFixed(1)},${(cy + y * s).toFixed(1)}`;
  const st = `fill="none" stroke="${col}" stroke-width="${(1.5 * s).toFixed(2)}" stroke-linecap="round" stroke-linejoin="round"`;
  switch (kind) {
    case 'overlord': return `<polygon points="${t(-5, 3)} ${t(-5, -2)} ${t(-2.5, 0.5)} ${t(0, -4)} ${t(2.5, 0.5)} ${t(5, -2)} ${t(5, 3)}" fill="${col}"/>`;
    case 'skeleton': return `<circle cx="${cx}" cy="${cy - 1 * s}" r="${4 * s}" fill="${col}"/><rect x="${cx - 2.2 * s}" y="${cy + 2 * s}" width="${4.4 * s}" height="${2.6 * s}" fill="${col}"/>` +
      `<circle cx="${cx - 1.6 * s}" cy="${cy - 1.2 * s}" r="${1.1 * s}" fill="${C.ink}"/><circle cx="${cx + 1.6 * s}" cy="${cy - 1.2 * s}" r="${1.1 * s}" fill="${C.ink}"/>`;
    case 'bone_archer': case 'archer': return `<path d="M ${t(-2, -5)} Q ${t(5, 0)} ${t(-2, 5)}" ${st}/><path d="M ${t(-2, -5)} L ${t(-2, 5)} M ${t(-4, 0)} L ${t(4.5, 0)}" ${st}/>`;
    case 'ghoul': return `<path d="M ${t(-4, -4)} L ${t(-2, 4)} M ${t(0, -4.5)} L ${t(0, 4.5)} M ${t(4, -4)} L ${t(2, 4)}" ${st}/>`;
    case 'shade': return `<path d="M ${t(-3.5, -1)} Q ${t(0, -6)} ${t(3.5, -1)} L ${t(3.5, 3)} L ${t(1.7, 1.5)} L ${t(0, 3)} L ${t(-1.7, 1.5)} L ${t(-3.5, 3)} Z" fill="${col}"/>`;
    case 'militia': return `<path d="M ${t(0, -6)} L ${t(-1.3, -4)} L ${t(-1.3, 2)} L ${t(1.3, 2)} L ${t(1.3, -4)} Z" fill="${col}"/><path d="M ${t(-3.6, 2.4)} L ${t(3.6, 2.4)} M ${t(0, 2.4)} L ${t(0, 5.6)}" ${st}/>`;
    case 'knight': return `<path d="M ${t(-4, -4)} L ${t(4, -4)} L ${t(4, 0)} Q ${t(3.5, 4)} ${t(0, 5)} Q ${t(-3.5, 4)} ${t(-4, 0)} Z" fill="${col}"/>`;
    case 'pyromancer': return `<path d="M ${t(0, -5)} Q ${t(5, 0)} ${t(2.5, 4)} Q ${t(0, 6)} ${t(-2.5, 4)} Q ${t(-5, 0)} ${t(0, -5)} Z" fill="${col}"/>`;
    case 'cleric': return `<path d="M ${t(0, -5)} L ${t(0, 5)} M ${t(-3.5, -1.5)} L ${t(3.5, -1.5)}" ${st}/>`;
    default: return '';
  }
}

function token(p, cx, cy, s) {
  const u = UNITS[p.k], ring = p.s === 'p' ? C.player : C.enemy, r = s * 0.36;
  let o = '';
  if (p.selected) o += `<rect x="${cx - s / 2 + 1.5}" y="${cy - s / 2 + 1.5}" width="${s - 3}" height="${s - 3}" rx="4" fill="${C.player}22" stroke="${C.player}" stroke-width="2"/>`;
  if (p.target) o += `<rect x="${cx - s / 2 + 1.5}" y="${cy - s / 2 + 1.5}" width="${s - 3}" height="${s - 3}" rx="4" fill="${C.threat}22" stroke="${C.threat}" stroke-width="2" stroke-dasharray="5 3"/>`;
  o += `<ellipse cx="${cx}" cy="${cy + r * 1.02}" rx="${r * 0.9}" ry="${r * 0.28}" fill="#000" opacity="0.45"/>`;
  o += shape(u.type, cx, cy - s * 0.04, r) + ` fill="${C.panel}" stroke="${ring}" stroke-width="${Math.max(1.6, s * 0.055)}"/>`;
  o += glyph(p.k, cx, cy - s * 0.04, r * 0.62, C[u.type]);
  const w = s * 0.7, hx = cx - w / 2, hy = cy + s * 0.38;
  o += `<rect x="${hx}" y="${hy}" width="${w}" height="${Math.max(2.5, s * 0.07)}" rx="1.5" fill="#000"/><rect x="${hx}" y="${hy}" width="${w * p.hp}" height="${Math.max(2.5, s * 0.07)}" rx="1.5" fill="${ring}"/>`;
  return o;
}

function corpseMark(cx, cy, s, n) {
  const r = s * 0.13;
  let o = `<g opacity="0.95"><circle cx="${cx - s * 0.2}" cy="${cy + s * 0.18}" r="${r}" fill="${C.corpse}"/><rect x="${cx - s * 0.2 - r * 0.55}" y="${cy + s * 0.18 + r * 0.6}" width="${r * 1.1}" height="${r * 0.7}" fill="${C.corpse}"/>` +
    `<path d="M ${cx - s * 0.02} ${cy + s * 0.3} l ${s * 0.26} ${-s * 0.1} M ${cx - s * 0.02} ${cy + s * 0.2} l ${s * 0.26} ${s * 0.1}" stroke="${C.corpse}" stroke-width="${Math.max(1.5, s * 0.05)}" stroke-linecap="round"/></g>`;
  if (n > 1) o += `<circle cx="${cx + s * 0.3}" cy="${cy - s * 0.28}" r="${s * 0.17}" fill="${C.ink}" stroke="${C.corpse}"/><text x="${cx + s * 0.3}" y="${cy - s * 0.28 + s * 0.07}" font-family="${SANS}" font-size="${s * 0.22}" fill="${C.text}" text-anchor="middle">${n}</text>`;
  return o;
}

function tile(ch, x, y, s, gx, gy) {
  const X = gx * s + x, Y = gy * s + y;
  let o = `<rect x="${X}" y="${Y}" width="${s}" height="${s}" fill="${(gx + gy) % 2 ? C.ground : C.ground2}"/>`;
  if (ch === 'f') o = `<rect x="${X}" y="${Y}" width="${s}" height="${s}" fill="${C.rough}"/>` +
    [[0.3, 0.62], [0.62, 0.4], [0.7, 0.75]].map(([a, b]) => `<path d="M ${X + a * s} ${Y + b * s} l ${-s * 0.11} ${s * 0.16} l ${s * 0.22} 0 Z" fill="${C.roughMark}"/>`).join('');
  if (ch === '#') o = `<rect x="${X}" y="${Y}" width="${s}" height="${s}" fill="${C.wall}"/><rect x="${X + 2}" y="${Y + 2}" width="${s - 4}" height="${s * 0.55}" rx="2" fill="${C.wallTop}"/>` +
    `<path d="M ${X + 2} ${Y + s * 0.3} h ${s - 4} M ${X + s * 0.5} ${Y + 2} v ${s * 0.28}" stroke="${C.wall}" stroke-width="1.5"/>`;
  if (ch === '~') o = `<rect x="${X}" y="${Y}" width="${s}" height="${s}" fill="${C.water}"/>` +
    [0.35, 0.68].map(b => `<path d="M ${X + s * 0.15} ${Y + b * s} q ${s * 0.12} ${-s * 0.1} ${s * 0.24} 0 t ${s * 0.24} 0 t ${s * 0.2} 0" fill="none" stroke="${C.waterMark}" stroke-width="1.5"/>`).join('');
  return o + `<rect x="${X}" y="${Y}" width="${s}" height="${s}" fill="none" stroke="#00000055" stroke-width="1"/>`;
}

// Draws the part of the map from column c0,row r0 that is cols x rows in size, with tiles of s points at (x,y).
function map(x, y, s, c0, r0, cols, rows, opt = {}) {
  let o = `<defs><pattern id="hatchH" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="3" height="8" fill="${C.holyGlow}" opacity="0.33"/></pattern>` +
    `<pattern id="hatchT" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(-45)"><rect width="2" height="8" fill="${C.threat}" opacity="0.38"/></pattern></defs>`;
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) o += tile(ROWS[r0 + r][c0 + c], x, y, s, c, r);
  const inView = (px, py) => px >= c0 && px < c0 + cols && py >= r0 && py < r0 + rows;
  const centre = (px, py) => [x + (px - c0 + 0.5) * s, y + (py - r0 + 0.5) * s];
  if (opt.threat) {
    for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) {
      const gx = c0 + c, gy = r0 + r;
      if (ROWS[gy][gx] === '#' || ROWS[gy][gx] === '~') continue;
      if (PIECES.some(p => p.s === 'e' && Math.abs(p.x - gx) + Math.abs(p.y - gy) <= (p.k === 'knight' ? 2 : 3)) && gx >= 9)
        o += `<rect x="${x + c * s}" y="${y + r * s}" width="${s}" height="${s}" fill="url(#hatchT)"/>`;
    }
  }
  for (const [bx, by] of BLESSED) if (inView(bx, by)) {
    const X = x + (bx - c0) * s, Y = y + (by - r0) * s;
    o += `<rect x="${X}" y="${Y}" width="${s}" height="${s}" fill="url(#hatchH)"/><rect x="${X + 1.5}" y="${Y + 1.5}" width="${s - 3}" height="${s - 3}" fill="none" stroke="${C.holyGlow}" stroke-width="1.2" opacity="0.8"/>` +
      `<path d="M ${X + s * 0.86} ${Y + s * 0.08} v ${s * 0.14} m ${-s * 0.05} ${-s * 0.09} h ${s * 0.1}" stroke="${C.holyGlow}" stroke-width="1.5"/>`;
  }
  for (const c of CORPSES) if (inView(c.x, c.y)) { const [cx, cy] = centre(c.x, c.y); o += corpseMark(cx, cy, s, c.n); }
  for (const p of PIECES) if (inView(p.x, p.y)) { const [cx, cy] = centre(p.x, p.y); o += token(p, cx, cy, s); }
  return o + `<rect x="${x}" y="${y}" width="${cols * s}" height="${rows * s}" fill="none" stroke="${C.line}" stroke-width="2"/>`;
}

const text = (x, y, t, size = 12, fill = C.text, extra = '') => `<text x="${x}" y="${y}" font-family="${SANS}" font-size="${size}" fill="${fill}" ${extra}>${t}</text>`;
const title = (x, y, t, size = 15, fill = C.text, extra = '') => `<text x="${x}" y="${y}" font-family="${SERIF}" font-size="${size}" fill="${fill}" letter-spacing="1.2" ${extra}>${t}</text>`;
const button = (x, y, w, h, label, kind = '') => {
  const fill = kind === 'primary' ? C.player : kind === 'danger' ? '#3a2228' : C.panel2, col = kind === 'primary' ? C.ink : C.text;
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="8" fill="${fill}" stroke="${kind === 'primary' ? C.player : C.line}"/>` + text(x + w / 2, y + h / 2 + 4.5, label, 12.5, col, 'text-anchor="middle" font-weight="bold"');
};
const capPips = (x, y, used, cap) => Array.from({ length: cap }, (_, i) => `<polygon points="${x + i * 15},${y - 6} ${x + i * 15 + 6},${y} ${x + i * 15},${y + 6} ${x + i * 15 - 6},${y}" fill="${i < used ? C.player : 'none'}" stroke="${C.player}" stroke-width="1.3"/>`).join('');
const chip = (x, y, label, col) => `<rect x="${x}" y="${y - 11}" width="${label.length * 6.6 + 14}" height="16" rx="8" fill="none" stroke="${col}"/>` + text(x + 7, y + 1, label, 10.5, col);

function unitCard(x, y, w) {
  let o = `<rect x="${x}" y="${y}" width="${w}" height="132" rx="10" fill="${C.panel2}" stroke="${C.line}"/>`;
  o += token({ k: 'ghoul', s: 'p', hp: 0.77 }, x + 30, y + 30, 46);
  o += title(x + 58, y + 26, 'GHOUL', 14) + chip(x + 58, y + 46, 'Flesh', C.flesh);
  o += text(x + 12, y + 76, 'HP 17 / 22', 12) + `<rect x="${x + 12}" y="${y + 82}" width="${w - 24}" height="5" rx="2.5" fill="#000"/><rect x="${x + 12}" y="${y + 82}" width="${(w - 24) * 0.77}" height="5" rx="2.5" fill="${C.player}"/>`;
  o += text(x + 12, y + 104, 'Mgt 11   Grd 2   Wrd 2', 10.5, C.dim) + text(x + 12, y + 120, 'Mov 5   Rng 1   Feed', 10.5, C.dim);
  return o;
}
function forecastCard(x, y, w) {
  let o = `<rect x="${x}" y="${y}" width="${w}" height="118" rx="10" fill="${C.panel2}" stroke="${C.threat}99"/>`;
  o += title(x + 12, y + 22, 'FORECAST', 11.5, C.dim) + text(x + 12, y + 42, 'Ghoul  →  Cleric', 12);
  o += `<text x="${x + 12}" y="${y + 70}" font-family="${SERIF}" font-size="26" fill="${C.text}">15</text>` + text(x + 54, y + 60, '▲ strong', 10.5, C.player) + text(x + 54, y + 75, 'kills if it hits', 10.5, C.holyGlow);
  o += text(x + 12, y + 94, 'Hit 85%    Crit 5%', 11.5) + text(x + 12, y + 110, 'Reply 4 · 65%', 10.5, C.dim);
  return o;
}

const svg = (w, h, body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><rect width="${w}" height="${h}" fill="${C.ink}"/>${body}</svg>`;

function openScreen() {
  const W = 890, H = 626, s = 44, mx = 12, my = 52;
  let o = `<rect width="${W}" height="44" fill="${C.panel}"/>` + title(16, 28, 'TURN 4', 14) + text(96, 28, 'Your phase', 12, C.player);
  o += text(300, 28, 'Command', 11, C.dim) + capPips(372, 24, 4, 5) + text(452, 28, '4 / 5', 11.5);
  o += button(590, 8, 78, 28, 'Threat') + button(676, 8, 60, 28, 'Menu');
  o += map(mx, my, s, 0, 0, 16, 12);
  o += text(mx, 606, 'Ghoul selected. Tap Confirm to attack the Cleric, or tap another tile to move.', 11.5, C.dim);
  const px = 730, pw = 148;
  o += unitCard(px, 52, pw) + forecastCard(px, 192, pw);
  o += button(px, 320, pw, 44, 'Confirm attack', 'primary') + button(px, 372, 70, 40, 'Raise') + button(px + 78, 372, 70, 40, 'Skill') + button(px, 420, 70, 40, 'Wait') + button(px + 78, 420, 70, 40, 'Undo');
  o += button(px, 536, pw, 44, 'End phase', 'danger');
  return svg(W, H, o);
}

function foldedScreen() {
  const W = 466, H = 678, s = 48, cols = 9, rows = 8, mx = 17, my = 46;
  let o = `<rect width="${W}" height="40" fill="${C.panel}"/>` + title(14, 26, 'TURN 4', 13) + text(84, 26, 'Your phase', 11.5, C.player) + capPips(250, 22, 4, 5) + text(328, 26, '4 / 5', 11) + button(396, 6, 56, 28, 'Menu');
  o += map(mx, my, s, 6, 3, cols, rows, { threat: true });
  const y = my + rows * s + 8;
  o += `<rect x="${mx}" y="${y}" width="${W - 2 * mx}" height="52" rx="10" fill="${C.panel2}" stroke="${C.line}"/>` + token({ k: 'ghoul', s: 'p', hp: 0.77 }, mx + 26, y + 24, 40);
  o += title(mx + 52, y + 21, 'GHOUL', 12.5) + text(mx + 52, y + 39, 'HP 17 / 22', 10.5, C.dim);
  o += text(mx + 150, y + 21, '→ Cleric   15 ▲', 12) + text(mx + 150, y + 39, 'Hit 85%   kills if it hits', 10.5, C.holyGlow);
  const by = y + 62;
  // mini-map
  const mw = 128, mh = 96, ms = 8;
  o += `<rect x="${mx}" y="${by}" width="${mw}" height="${mh}" rx="6" fill="${C.panel}" stroke="${C.line}"/>`;
  for (let r = 0; r < 12; r++) for (let c = 0; c < 16; c++) { const ch = ROWS[r][c]; if (ch !== '.') o += `<rect x="${mx + c * ms}" y="${by + r * ms}" width="${ms}" height="${ms}" fill="${ch === 'f' ? C.rough : ch === '#' ? C.wall : C.water}"/>`; }
  for (const p of PIECES) o += `<rect x="${mx + p.x * ms + 1.5}" y="${by + p.y * ms + 1.5}" width="${ms - 3}" height="${ms - 3}" fill="${p.s === 'p' ? C.player : C.enemy}"/>`;
  for (const c of CORPSES) o += `<circle cx="${mx + c.x * ms + 4}" cy="${by + c.y * ms + 4}" r="1.8" fill="${C.corpse}"/>`;
  o += `<rect x="${mx + 6 * ms}" y="${by + 3 * ms}" width="${cols * ms}" height="${rows * ms}" fill="none" stroke="${C.text}" stroke-width="1.5"/>`;
  const bx = mx + mw + 12, bw = (W - mx - bx - 10) / 2;
  o += button(bx, by, bw * 2 + 10, 44, 'Confirm attack', 'primary') + button(bx, by + 52, bw, 44, 'Raise') + button(bx + bw + 10, by + 52, bw, 44, 'Undo');
  o += button(mx, by + mh + 10, 74, 34, 'Overview') + button(mx + 78, by + mh + 10, 50, 34, 'Threat') + button(bx, by + 104, bw, 34, '‹ Unit') + button(bx + bw + 10, by + 104, bw, 34, 'Unit ›');
  return svg(W, H, o);
}

function tabletopScreen() {
  const W = 626, H = 890, s = 34, mx = 41, my = 30, fold = 445;
  let o = title(mx, 20, 'TURN 4', 12) + text(mx + 62, 20, 'Your phase', 10.5, C.player) + capPips(mx + 430, 16, 4, 5) + text(mx + 506, 20, '4 / 5', 10.5);
  o += map(mx, my, s, 0, 0, 16, 12);
  o += `<defs><linearGradient id="fold" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="0.5" stop-color="#000" stop-opacity="0.75"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient></defs>`;
  o += `<rect x="0" y="${fold - 9}" width="${W}" height="18" fill="url(#fold)"/><line x1="0" x2="${W}" y1="${fold}" y2="${fold}" stroke="${C.line}" stroke-dasharray="3 5"/>`;
  const y = fold + 22;
  o += unitCard(24, y, 190) + forecastCard(226, y, 180);
  o += button(418, y, 184, 52, 'Confirm attack', 'primary') + button(418, y + 62, 88, 56, 'Raise') + button(514, y + 62, 88, 56, 'Skill');
  const py = y + 150;
  o += `<rect x="24" y="${py}" width="300" height="230" rx="14" fill="${C.panel}" stroke="${C.line}"/>` + text(174, py + 110, 'Touch pad', 13, C.dim, 'text-anchor="middle"') + text(174, py + 130, 'drag to move the map cursor', 10.5, C.dim, 'text-anchor="middle"');
  o += `<circle cx="210" cy="${py + 70}" r="16" fill="${C.player}33" stroke="${C.player}"/>`;
  o += button(340, py, 126, 52, 'Wait') + button(476, py, 126, 52, 'Undo') + button(340, py + 62, 126, 52, 'Threat') + button(476, py + 62, 126, 52, 'Overview');
  o += button(340, py + 124, 126, 44, '‹ Unit') + button(476, py + 124, 126, 44, 'Unit ›') + button(340, py + 178, 262, 52, 'End phase', 'danger');
  return svg(W, H, o);
}

function styleSheet() {
  const W = 1000, H = 800;
  let o = title(36, 52, 'NECROMANCER TACTICS', 26) + text(36, 74, 'Working title. Look and feel, first pass: code-drawn placeholders, not final art.', 12.5, C.dim);
  // palette
  o += title(36, 118, 'PALETTE', 13, C.dim);
  const sw = [['Ink', C.ink], ['Panel', C.panel2], ['Ground', C.ground], ['Rough', C.rough], ['Wall', C.wall], ['Water', C.water], ['Yours', C.player], ['Theirs', C.enemy], ['Holy', C.holyGlow], ['Threat', C.threat]];
  sw.forEach(([n, c], i) => { o += `<rect x="${36 + i * 94}" y="130" width="82" height="46" rx="8" fill="${c}" stroke="${C.line}"/>` + text(36 + i * 94, 194, n, 11) + text(36 + i * 94, 208, c, 9.5, C.dim); });
  // types
  o += title(36, 252, 'SIX TYPES, EACH WITH ITS OWN SHAPE AND COLOUR', 13, C.dim);
  const types = [['bone', 'Bone', 'skeleton', 'p'], ['flesh', 'Flesh', 'ghoul', 'p'], ['spirit', 'Spirit', 'shade', 'p'], ['steel', 'Steel', 'knight', 'e'], ['flame', 'Flame', 'pyromancer', 'e'], ['holy', 'Holy', 'cleric', 'e'], ['sovereign', 'Sovereign', 'overlord', 'p']];
  types.forEach(([t, n, k, s], i) => { const cx = 80 + i * 134; o += token({ k, s, hp: 1 }, cx, 306, 84) + text(cx, 366, n, 13, C[t], 'text-anchor="middle" font-weight="bold"') + text(cx, 382, UNITS[k].name, 10.5, C.dim, 'text-anchor="middle"'); });
  o += text(36, 412, 'Green ring: your undead. Gold ring: the living. Shape tells the type, so nothing depends on colour alone.', 11.5, C.dim);
  // roster
  o += title(36, 452, 'THE SLICE ROSTER AT MAP SIZE', 13, C.dim);
  ['overlord', 'skeleton', 'bone_archer', 'ghoul', 'militia', 'archer', 'knight', 'cleric', 'pyromancer'].forEach((k, i) => {
    const cx = 62 + i * 76; o += `<rect x="${cx - 26}" y="466" width="52" height="52" fill="${C.ground}" stroke="#00000055"/>` + token({ k, s: i < 4 ? 'p' : 'e', hp: 1 }, cx, 492, 52) + text(cx, 536, UNITS[k].name, 9.5, C.dim, 'text-anchor="middle"');
  });
  // tile states
  o += title(36, 580, 'WHAT A TILE CAN TELL YOU', 13, C.dim);
  const s = 56; const st = ['Open', 'Rough', 'Wall', 'Water', 'A body', 'A pile', 'Consecrated', 'Enemy reach'];
  st.forEach((n, i) => {
    const X = 36 + (i % 4) * 236, ty = 594 + Math.floor(i / 4) * 72; const ch = ['.', 'f', '#', '~', '.', '.', '.', '.'][i];
    o += tile(ch, X, ty, s, 0, 0);
    if (i === 4) o += corpseMark(X + s / 2, ty + s / 2, s, 1);
    if (i === 5) o += corpseMark(X + s / 2, ty + s / 2, s, 3);
    if (i === 6) o += `<defs><pattern id="h2" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="3" height="8" fill="${C.holyGlow}" opacity="0.33"/></pattern></defs><rect x="${X}" y="${ty}" width="${s}" height="${s}" fill="url(#h2)"/><rect x="${X + 1.5}" y="${ty + 1.5}" width="${s - 3}" height="${s - 3}" fill="none" stroke="${C.holyGlow}" stroke-width="1.2"/>` + corpseMark(X + s / 2, ty + s / 2, s, 1);
    if (i === 7) o += `<defs><pattern id="t2" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(-45)"><rect width="2" height="8" fill="${C.threat}" opacity="0.5"/></pattern></defs><rect x="${X}" y="${ty}" width="${s}" height="${s}" fill="url(#t2)"/>`;
    o += text(X + s + 8, ty + s / 2 + 4, n, 11);
  });
  o += text(36, 768, 'A body on consecrated ground cannot be raised until the cleric who blessed it falls.', 11.5, C.dim);
  return svg(W, H, o);
}

(async () => {
  const out = process.argv[2] || '.';
  const browser = await chromium.launch();
  const shots = [['01-style-sheet', styleSheet()], ['02-open-inner-display', openScreen()], ['03-folded-outer-display', foldedScreen()], ['04-tabletop-half-folded', tabletopScreen()]];
  for (const [name, markup] of shots) {
    const m = markup.match(/width="(\d+)" height="(\d+)"/);
    const page = await browser.newPage({ viewport: { width: +m[1], height: +m[2] }, deviceScaleFactor: 2 });
    await page.setContent(`<html><body style="margin:0;background:${C.ink}">${markup}</body></html>`);
    await page.screenshot({ path: path.join(out, name + '.png') });
    await page.close();
    console.log(name, m[1] + 'x' + m[2]);
  }
  await browser.close();
})();
