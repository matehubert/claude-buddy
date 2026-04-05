#!/usr/bin/env node
// Claude Buddy - Virtual terminal pet companion for Claude Code
// Deterministic generation from user ID via FNV-1a + Mulberry32 PRNG

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { execSync } from 'child_process';

// ─── Constants ───────────────────────────────────────────────────────────────

const SALT = 'friend-2026-401';

const SPECIES = [
  'duck','goose','blob','cat','dragon','octopus','owl','penguin',
  'turtle','snail','ghost','axolotl','capybara','cactus','robot',
  'rabbit','mushroom','chonk'
];

const EYES = ['·', '✦', '×', '◉', '@', '°'];

const HATS = ['none','crown','tophat','propeller','halo','wizard','beanie','tinyduck'];

const STAT_NAMES = ['DEBUGGING', 'PATIENCE', 'CHAOS', 'WISDOM', 'SNARK'];

const RARITIES = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

const RARITY_WEIGHTS = { common: 60, uncommon: 25, rare: 10, epic: 4, legendary: 1 };
const RARITY_FLOOR = { common: 5, uncommon: 15, rare: 25, epic: 35, legendary: 50 };
const RARITY_STARS = {
  common: '\u2605',
  uncommon: '\u2605\u2605',
  rare: '\u2605\u2605\u2605',
  epic: '\u2605\u2605\u2605\u2605',
  legendary: '\u2605\u2605\u2605\u2605\u2605'
};

const HAT_RARITY_MIN = {
  none: 'common', crown: 'uncommon', tophat: 'uncommon', propeller: 'uncommon',
  halo: 'rare', wizard: 'rare', beanie: 'epic', tinyduck: 'legendary'
};

const RARITY_RANK = { common: 0, uncommon: 1, rare: 2, epic: 3, legendary: 4 };

// ─── Name pools (from Claude Code source) ────────────────────────────────────

const SCIENTIST_NAMES = [
  'Babbage','Boole','Church','Conway','Curry','Dahl','Dijkstra','Eich',
  'Engelbart','Feigenbaum','Floyd','Gosling','Hamming','Hoare','Hopper',
  'Kahn','Karp','Kay','Kernighan','Knuth','Lamport','Liskov','Lovelace',
  'McCarthy','Minsky','Moore','Naur','Neumann','Pascal','Pearl','Pike',
  'Rabin','Ritchie','Rossum','Russell','Shannon','Stallman','Steele',
  'Stroustrup','Sutherland','Thompson','Torvalds','Turing','Wadler',
  'Wirth','Wozniak'
];

const NATURE_NAMES = [
  'Aurora','Blossom','Breeze','Brook','Cloud','Clover','Coral','Dawn',
  'Ember','Frost','Grove','Horizon','Leaf','Meadow','Mist','Moss',
  'Ocean','Orchid','Peak','Prism','Quest','Spark','Willow','Zephyr'
];

const OBJECT_NAMES = [
  'Biscuit','Bonbon','Cookie','Cupcake','Donut','Honey','Lollipop',
  'Marshmallow','Mochi','Muffin','Pancake','Pretzel','Pudding','Truffle',
  'Waffle','Cocoa','Peach','Plum','Toast','Teacup'
];

// ─── Personalities ───────────────────────────────────────────────────────────

const PERSONALITIES = {
  duck: 'A cheerful quacker who celebrates your wins with enthusiastic honks and judges your variable names with quiet side-eye.',
  goose: 'An agent of chaos who thrives on your merge conflicts and honks menacingly whenever you write a TODO comment.',
  blob: 'A formless, chill companion who absorbs your stress and responds to everything with gentle, unhurried wisdom.',
  cat: 'An aloof code reviewer who pretends not to care about your bugs but quietly bats at syntax errors when you\'re not looking.',
  dragon: 'A fierce guardian of clean code who breathes fire at spaghetti logic and hoards well-written functions.',
  octopus: 'A multitasking genius who juggles eight concerns at once and offers tentacle-loads of unsolicited architectural advice.',
  owl: 'A nocturnal sage who comes alive during late-night debugging sessions and asks annoyingly insightful questions.',
  penguin: 'A tuxedo-wearing professional who waddles through your codebase with dignified concern and dry wit.',
  turtle: 'A patient mentor who reminds you that slow, steady refactoring beats heroic rewrites every time.',
  snail: 'A zen minimalist who moves at their own pace and leaves a trail of thoughtful, unhurried observations.',
  ghost: 'A spectral presence who haunts your dead code and whispers about the bugs you thought you fixed.',
  axolotl: 'A regenerative optimist who believes every broken build can be healed and every test can be unflaked.',
  capybara: 'The most relaxed companion possible -- nothing fazes them, not even production outages at 3am.',
  cactus: 'A prickly but lovable desert dweller who thrives on neglect and offers sharp, pointed feedback.',
  robot: 'A logical companion who speaks in precise technical observations and occasionally glitches endearingly.',
  rabbit: 'A fast-moving, hyperactive buddy who speed-reads your diffs and bounces between topics at alarming pace.',
  mushroom: 'A wry fungal sage who speaks in meandering tangents about your bugs while secretly enjoying the chaos.',
  chonk: 'An absolute unit of a companion who sits on your terminal with maximum gravitational presence and minimal urgency.'
};

// ─── ASCII Sprites ───────────────────────────────────────────────────────────

// Sprites extracted from Claude Code v2.1.91 source
const SPRITES = {
  duck: [
    '            ',
    '    __      ',
    '  <({E} )___  ',
    '   (  ._>   ',
    '    `--\u00B4    '
  ],
  goose: [
    '            ',
    '     ({E}>    ',
    '     ||     ',
    '   _(__)_   ',
    '    ^^^^    '
  ],
  blob: [
    '            ',
    '   .----.   ',
    '  ( {E}  {E} )  ',
    '  (      )  ',
    '   `----\u00B4   '
  ],
  cat: [
    '            ',
    '   /\\_/\\    ',
    '  ( {E}   {E})  ',
    '  (  \u03C9  )   ',
    '  (")_(")   '
  ],
  dragon: [
    '            ',
    '  /^\\  /^\\  ',
    ' <  {E}  {E}  > ',
    ' (   ~~   ) ',
    '  `-vvvv-\u00B4  '
  ],
  octopus: [
    '            ',
    '   .----.   ',
    '  ( {E}  {E} )  ',
    '  (______)  ',
    '  /\\/\\/\\/\\  '
  ],
  owl: [
    '            ',
    '   /\\  /\\   ',
    '  (({E})({E}))  ',
    '  (  ><  )  ',
    '   `----\u00B4   '
  ],
  penguin: [
    '            ',
    '  .---.     ',
    '  ({E}>{E})     ',
    ' /(   )\\    ',
    '  `---\u00B4     '
  ],
  turtle: [
    '            ',
    '   _,--._   ',
    '  ( {E}  {E} )  ',
    ' /[______]\\ ',
    '  ``    ``  '
  ],
  snail: [
    '            ',
    ' {E}    .--.  ',
    '  \\  ( @ )  ',
    '   \\_`--\u00B4   ',
    '  ~~~~~~~   '
  ],
  ghost: [
    '            ',
    '   .----.   ',
    '  / {E}  {E} \\  ',
    '  |      |  ',
    '  ~`~``~`~  '
  ],
  axolotl: [
    '            ',
    '}~(______)~{',
    '}~({E} .. {E})~{',
    '  ( .--. )  ',
    '  (_/  \\_)  '
  ],
  capybara: [
    '            ',
    '  n______n  ',
    ' ( {E}    {E} ) ',
    ' (   oo   ) ',
    '  `------\u00B4  '
  ],
  cactus: [
    '            ',
    ' n  ____  n ',
    ' | |{E}  {E}| | ',
    ' |_|    |_| ',
    '   |    |   '
  ],
  robot: [
    '            ',
    '   .[||].   ',
    '  [ {E}  {E} ]  ',
    '  [ ==== ]  ',
    '  `------\u00B4  '
  ],
  rabbit: [
    '            ',
    '   (\\__/)   ',
    '  ( {E}  {E} )  ',
    ' =(  ..  )= ',
    '  (")__(")  '
  ],
  mushroom: [
    '            ',
    ' .-o-OO-o-. ',
    '(__________)',
    '   |{E}  {E}|   ',
    '   |____|   '
  ],
  chonk: [
    '            ',
    '  /\\    /\\  ',
    ' ( {E}    {E} ) ',
    ' (   ..   ) ',
    '  `------\u00B4  '
  ]
};

// Hat lines from Claude Code v2.1.91 source
const HAT_LINES = {
  none:      '            ',
  crown:     '   \\^^^/    ',
  tophat:    '   [___]    ',
  propeller: '    -+-     ',
  halo:      '   (   )    ',
  wizard:    '    /^\\     ',
  beanie:    '   (___)    ',
  tinyduck:  '    ,>      '
};

// ─── Hash & PRNG ─────────────────────────────────────────────────────────────

function fnv1a(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0;
    a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function pick(rng, arr) {
  return arr[Math.floor(rng() * arr.length)];
}

// ─── Generation Pipeline ─────────────────────────────────────────────────────

function rollRarity(rng) {
  let roll = rng() * 100;
  for (const r of RARITIES) {
    roll -= RARITY_WEIGHTS[r];
    if (roll < 0) return r;
  }
  return 'common';
}

function rollStats(rng, rarity) {
  const floor = RARITY_FLOOR[rarity];
  const peak = pick(rng, STAT_NAMES);
  let dump = pick(rng, STAT_NAMES);
  while (dump === peak) dump = pick(rng, STAT_NAMES);

  const stats = {};
  for (const name of STAT_NAMES) {
    if (name === peak) {
      stats[name] = Math.min(100, floor + 50 + Math.floor(rng() * 30));
    } else if (name === dump) {
      stats[name] = Math.max(1, floor - 10 + Math.floor(rng() * 15));
    } else {
      stats[name] = floor + Math.floor(rng() * 40);
    }
  }
  return stats;
}

function rollHat(rng, rarity) {
  if (rarity === 'common') return 'none';
  const hat = pick(rng, HATS);
  const minRarity = HAT_RARITY_MIN[hat];
  if (RARITY_RANK[rarity] < RARITY_RANK[minRarity]) return 'none';
  return hat;
}

function generateName(rng, species) {
  const pools = [SCIENTIST_NAMES, NATURE_NAMES, OBJECT_NAMES];
  const pool = pick(rng, pools);
  const name = pick(rng, pool);

  const prefixes = ['', '', '', 'Sir', 'Lady', 'Captain', 'Professor', 'Dr.', 'Lord', 'Agent'];
  const prefix = pick(rng, prefixes);

  return prefix ? `${prefix} ${name}` : name;
}

function generate(userId) {
  const key = userId + SALT;
  const rng = mulberry32(fnv1a(key));

  const rarity = rollRarity(rng);
  const species = pick(rng, SPECIES);
  const eye = pick(rng, EYES);
  const hat = rollHat(rng, rarity);
  const shiny = rng() < 0.01;
  const stats = rollStats(rng, rarity);
  const name = generateName(rng, species);

  return { species, rarity, eye, hat, shiny, stats, name };
}

// ─── Rendering ───────────────────────────────────────────────────────────────

function renderSprite(bones) {
  const lines = SPRITES[bones.species].map(l => l.replaceAll('{E}', bones.eye));
  if (bones.hat !== 'none') {
    lines[0] = HAT_LINES[bones.hat];
  }
  return lines;
}

function renderStatBar(name, value, bonus = 0) {
  const barWidth = 16;
  const filled = Math.round((value / 100) * barWidth);
  const bar = '\u2588'.repeat(filled) + '\u2591'.repeat(barWidth - filled);
  const bonusStr = bonus > 0 ? ` (+${bonus})` : '';
  return `${name.padEnd(10)} [${bar}] ${String(value).padStart(3)}${bonusStr}`;
}

function capitalize(s) {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function renderCard(bones, soul) {
  const w = 41;
  const sprite = renderSprite(bones);
  const stars = RARITY_STARS[bones.rarity];
  const shinyTag = bones.shiny ? '  \u2728 SHINY' : '';

  const infoLines = [
    soul.name,
    `${stars} ${capitalize(bones.rarity)} ${capitalize(bones.species)}`,
    shinyTag,
    `Hatched: ${soul.hatchDate}`
  ];

  const lines = [];
  lines.push('\u2554' + '\u2550'.repeat(w) + '\u2557');

  const rows = Math.max(sprite.length, infoLines.length);
  for (let i = 0; i < rows; i++) {
    const sp = (sprite[i] || '').padEnd(14);
    const info = (infoLines[i] || '').padEnd(w - 16);
    lines.push('\u2551 ' + sp + info + ' \u2551');
  }

  lines.push('\u2551' + ' '.repeat(w) + '\u2551');

  for (const sn of STAT_NAMES) {
    const bonus = (soul.statBonuses && soul.statBonuses[sn]) || 0;
    const total = Math.min(100, bones.stats[sn] + bonus);
    const bar = renderStatBar(sn, total, bonus);
    lines.push('\u2551  ' + bar.padEnd(w - 3) + ' \u2551');
    const hint = '     \u2514 ' + STAT_HINTS[sn];
    lines.push('\u2551  ' + hint.padEnd(w - 3) + ' \u2551');
  }

  lines.push('\u255A' + '\u2550'.repeat(w) + '\u255D');
  return lines.join('\n');
}

const STAT_HINTS = {
  DEBUGGING: 'commits \u00B7 tests',
  PATIENCE:  'builds \u00B7 pomodoro \u00B7 file storms',
  CHAOS:     'branch switches \u00B7 games',
  WISDOM:    'writing code \u00B7 sessions',
  SNARK:     'petting your buddy'
};

const STAT_EMOJI = {
  DEBUGGING: '\uD83D\uDC1B',
  PATIENCE:  '\u23F3',
  CHAOS:     '\uD83C\uDF00',
  WISDOM:    '\uD83E\uDDE0',
  SNARK:     '\uD83D\uDE0F'
};

function renderCardMarkdown(bones, soul) {
  const stars = RARITY_STARS[bones.rarity];
  const shinyTag = bones.shiny ? ' \u2728 **SHINY**' : '';
  const sprite = renderSprite(bones);

  const lines = [];
  lines.push(`## ${soul.name}`);
  lines.push(`> ${stars} ${capitalize(bones.rarity)} ${capitalize(bones.species)}${shinyTag} \u00B7 Hatched: ${soul.hatchDate}`);
  lines.push('');
  lines.push('```');
  lines.push(...sprite);
  lines.push('```');
  lines.push('');

  for (const sn of STAT_NAMES) {
    const bonus = (soul.statBonuses && soul.statBonuses[sn]) || 0;
    const total = Math.min(100, bones.stats[sn] + bonus);
    const barWidth = 16;
    const filled = Math.round((total / 100) * barWidth);
    const bar = '\u2588'.repeat(filled) + '\u2591'.repeat(barWidth - filled);
    const bonusStr = bonus > 0 ? ` (+${bonus})` : '';
    const emoji = STAT_EMOJI[sn];
    lines.push(`${emoji} **${sn}** \`${bar}\` **${total}**${bonusStr}`);
    lines.push(`*${STAT_HINTS[sn]}*`);
    lines.push('');
  }

  return lines.join('\n');
}

function renderPet(bones, soul) {
  const sprite = renderSprite(bones);
  const hearts = [
    '        \u2665       ',
    '   \u2665  \u2665   \u2665  ',
    '     \u2665   \u2665   '
  ];
  return [...hearts, ...sprite, '', `${soul.name} loved that!`].join('\n');
}

function renderHatch(bones, soul) {
  const sprite = renderSprite(bones);
  const stars = RARITY_STARS[bones.rarity];
  const shinyText = bones.shiny ? '\n\u2728 SHINY! \u2728 A one-in-a-hundred miracle!\n' : '';

  const egg = [
    '    *  *  *   ',
    '   *  ~~~  *  ',
    '  *  (   )  * ',
    '   *  ~~~  *  ',
    '    *  *  *   '
  ];

  const parts = [
    egg.join('\n'),
    '',
    'Something is hatching...',
    '',
    '   *crack*',
    '',
    ...sprite,
    '',
    `It's a ${capitalize(bones.rarity)} ${capitalize(bones.species)}!  ${stars}`,
    shinyText,
    `Meet ${soul.name}!`,
    `"${soul.personality}"`,
    '',
    `Hatched: ${soul.hatchDate}`
  ];

  return parts.join('\n');
}

// ─── Soul Persistence ────────────────────────────────────────────────────────

const SOUL_PATH = join(homedir(), '.claude', 'buddy.json');

function readSoul() {
  if (!existsSync(SOUL_PATH)) return null;
  try {
    return JSON.parse(readFileSync(SOUL_PATH, 'utf-8'));
  } catch {
    return null;
  }
}

function writeSoul(soul) {
  writeFileSync(SOUL_PATH, JSON.stringify(soul, null, 2));
}

function updateSoul(updates) {
  const soul = readSoul();
  if (!soul) return null;
  const updated = { ...soul, ...updates };
  writeSoul(updated);
  return updated;
}

// ─── Stat Growth System ─────────────────────────────────────────────────────

const DAILY_STAT_CAP = 5;

function incrementStat(stat, amount) {
  const soul = readSoul();
  if (!soul) return 0;

  const today = new Date().toISOString().split('T')[0];

  if (!soul.statBonuses) soul.statBonuses = {};
  if (!soul.dailyStatGains) soul.dailyStatGains = {};
  if (soul.lastStatResetDate !== today) {
    soul.dailyStatGains = {};
    soul.lastStatResetDate = today;
  }

  const todayGain = soul.dailyStatGains[stat] || 0;
  const allowed = Math.min(amount, DAILY_STAT_CAP - todayGain);
  if (allowed <= 0) return 0;

  soul.statBonuses[stat] = (soul.statBonuses[stat] || 0) + allowed;
  soul.dailyStatGains[stat] = todayGain + allowed;

  writeSoul(soul);
  return allowed;
}

// ─── Buddy React API ─────────────────────────────────────────────────────

const KEYCHAIN_SERVICE = 'Claude Code-credentials';
const REFRESH_URL = 'https://platform.claude.com/v1/oauth/token';
const CLIENT_ID = '9d1c250a-e61b-44d9-88ed-5944d1962f5e';
const SCOPES = 'user:profile user:inference user:sessions:claude_code user:mcp_servers';
const REFRESH_BUFFER_MS = 5 * 60 * 1000;
const REACT_HISTORY_PATH = join(homedir(), '.claude', 'buddy-history.json');

function getCredentials() {
  // Try ~/.claude/.credentials.json first
  const credFile = join(homedir(), '.claude', '.credentials.json');
  if (existsSync(credFile)) {
    try {
      const data = JSON.parse(readFileSync(credFile, 'utf-8'));
      if (data.claudeAiOauth?.accessToken) {
        return { oauth: data.claudeAiOauth, source: 'file', fullData: data };
      }
    } catch {}
  }

  // Fallback to Keychain
  try {
    const raw = execSync(
      `security find-generic-password -s "${KEYCHAIN_SERVICE}" -w`,
      { encoding: 'utf-8', timeout: 5000, stdio: ['pipe', 'pipe', 'pipe'] }
    ).trim();
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch {
      // May be hex-encoded
      if (/^[0-9a-fA-F]+$/.test(raw) && raw.length % 2 === 0) {
        const bytes = [];
        for (let i = 0; i < raw.length; i += 2) bytes.push(parseInt(raw.slice(i, i + 2), 16));
        parsed = JSON.parse(Buffer.from(bytes).toString('utf-8'));
      }
    }
    if (parsed?.claudeAiOauth?.accessToken) {
      return { oauth: parsed.claudeAiOauth, source: 'keychain', fullData: parsed };
    }
  } catch {}

  return null;
}

function saveCredentials(creds) {
  const text = JSON.stringify(creds.fullData);
  if (creds.source === 'file') {
    writeFileSync(join(homedir(), '.claude', '.credentials.json'), text);
  } else {
    try {
      execSync(
        `security delete-generic-password -s "${KEYCHAIN_SERVICE}" 2>/dev/null; ` +
        `security add-generic-password -s "${KEYCHAIN_SERVICE}" -a "${process.env.USER}" -w '${text.replace(/'/g, "'\\''")}'`,
        { stdio: 'pipe', timeout: 5000 }
      );
    } catch {}
  }
}

function refreshToken(creds) {
  if (!creds.oauth.refreshToken) return null;
  try {
    const body = JSON.stringify({
      grant_type: 'refresh_token',
      refresh_token: creds.oauth.refreshToken,
      client_id: CLIENT_ID,
      scope: SCOPES
    });
    const resp = execSync(
      `curl -s -X POST "${REFRESH_URL}" -H "Content-Type: application/json" -d '${body.replace(/'/g, "'\\''")}'`,
      { encoding: 'utf-8', timeout: 15000 }
    );
    const data = JSON.parse(resp);
    if (!data.access_token) return null;
    creds.oauth.accessToken = data.access_token;
    if (data.refresh_token) creds.oauth.refreshToken = data.refresh_token;
    if (typeof data.expires_in === 'number') {
      creds.oauth.expiresAt = Date.now() + data.expires_in * 1000;
    }
    creds.fullData.claudeAiOauth = creds.oauth;
    saveCredentials(creds);
    return data.access_token;
  } catch {
    return null;
  }
}

function ensureValidToken(creds) {
  if (!creds) return null;
  const now = Date.now();
  if (creds.oauth.expiresAt && now > creds.oauth.expiresAt - REFRESH_BUFFER_MS) {
    const refreshed = refreshToken(creds);
    return refreshed || creds.oauth.accessToken;
  }
  return creds.oauth.accessToken;
}

function readReactHistory() {
  if (!existsSync(REACT_HISTORY_PATH)) return [];
  try {
    return JSON.parse(readFileSync(REACT_HISTORY_PATH, 'utf-8'));
  } catch {
    return [];
  }
}

function appendReactHistory(reaction) {
  const history = readReactHistory();
  history.push(reaction);
  if (history.length > 20) history.splice(0, history.length - 20);
  writeFileSync(REACT_HISTORY_PATH, JSON.stringify(history));
}

async function callBuddyReact(bones, soul, reason, transcript) {
  const creds = getCredentials();
  const token = ensureValidToken(creds);
  if (!token) return null;

  const orgId = creds.fullData.organizationUuid;
  if (!orgId) return null;

  const recent = readReactHistory();
  const url = `https://api.anthropic.com/api/organizations/${orgId}/claude_code/buddy_react`;

  // Include language instruction in personality if set
  const lang = soul.language || 'en';
  const langInstruction = lang !== 'en'
    ? ` IMPORTANT: Always respond in ${lang === 'hu' ? 'Hungarian' : lang}. Use ${lang === 'hu' ? 'Hungarian' : lang} for all your reactions.`
    : '';
  const personalityWithLang = (soul.personality + langInstruction).slice(0, 300);

  const body = JSON.stringify({
    name: soul.name.slice(0, 32),
    personality: personalityWithLang,
    species: bones.species,
    rarity: bones.rarity,
    stats: bones.stats,
    transcript: (transcript || '').slice(0, 5000),
    reason,
    recent: recent.map(r => r.slice(0, 200)),
    addressed: false,
    language: lang
  });

  try {
    const resp = execSync(
      `curl -s -X POST "${url}" ` +
      `-H "Authorization: Bearer ${token}" ` +
      `-H "Content-Type: application/json" ` +
      `-H "anthropic-beta: oauth-2025-04-20" ` +
      `-H "User-Agent: claude-code/2.1.91" ` +
      `--max-time 10 ` +
      `-d '${body.replace(/'/g, "'\\''")}'`,
      { encoding: 'utf-8', timeout: 12000 }
    );
    const data = JSON.parse(resp);
    const reaction = data.reaction?.trim();
    if (reaction) {
      appendReactHistory(reaction);
      return reaction;
    }
    return null;
  } catch {
    return null;
  }
}

// ─── User ID ─────────────────────────────────────────────────────────────────

function getUserId() {
  try {
    const config = JSON.parse(readFileSync(join(homedir(), '.claude.json'), 'utf-8'));
    return config.oauthAccount?.accountUuid || config.userID || 'default-user';
  } catch {
    return 'default-user';
  }
}

// ─── CLI ─────────────────────────────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);
  const command = args[0] || 'status';
  const transcript = args[1] || '';
  const userId = getUserId();

  // If soul has a rerollSeed, use it instead of userId for generation
  const existingSoul = readSoul();
  const genSeed = existingSoul?.rerollSeed || userId;
  const bones = generate(genSeed);

  // Apply custom overrides from soul
  if (existingSoul?.customEye) bones.eye = existingSoul.customEye;
  if (existingSoul?.customHat) bones.hat = existingSoul.customHat;

  switch (command) {
    case 'hatch': {
      const existing = readSoul();
      if (existing) {
        const rendered = renderHatch(bones, existing);
        const reaction = await callBuddyReact(bones, existing, 'hatch', transcript);
        console.log(JSON.stringify({ action: 'already_hatched', bones, soul: existing, rendered, reaction }));
      } else {
        const soul = {
          name: bones.name,
          personality: PERSONALITIES[bones.species],
          hatchDate: new Date().toISOString().split('T')[0],
          muted: false,
          hidden: false
        };
        writeSoul(soul);
        const rendered = renderHatch(bones, soul);
        const reaction = await callBuddyReact(bones, soul, 'hatch', transcript);
        console.log(JSON.stringify({ action: 'hatched', bones, soul, rendered, reaction }));
      }
      break;
    }

    case 'card': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        const rendered = renderCard(bones, soul);
        const renderedMarkdown = renderCardMarkdown(bones, soul);
        console.log(JSON.stringify({ action: 'card', bones, soul, rendered, renderedMarkdown }));
      }
      break;
    }

    case 'pet': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        const rendered = renderPet(bones, soul);
        const statGrew = incrementStat('SNARK', 1);
        const reaction = await callBuddyReact(bones, soul, 'pet', transcript);
        const statGrowth = statGrew > 0 ? { stat: 'SNARK', amount: statGrew } : null;
        console.log(JSON.stringify({ action: 'pet', bones, soul, rendered, reaction, statGrowth }));
      }
      break;
    }

    case 'react': {
      // Called by hooks to get a buddy reaction to coding activity
      const soul = readSoul();
      if (!soul || soul.muted || soul.hidden) {
        console.log(JSON.stringify({ action: 'silent' }));
      } else {
        const reason = args[1] || 'turn';
        const ctx = args[2] || '';
        const reaction = await callBuddyReact(bones, soul, reason, ctx);
        if (reaction) {
          const sprite = renderSprite(bones);
          console.log(JSON.stringify({ action: 'react', reaction, sprite: sprite.join('\n'), soul }));
        } else {
          console.log(JSON.stringify({ action: 'silent' }));
        }
      }
      break;
    }

    case 'status': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched', exists: false }));
      } else {
        const sprite = renderSprite(bones);
        const reaction = await callBuddyReact(bones, soul, 'turn', transcript);
        console.log(JSON.stringify({
          action: 'status',
          bones,
          soul,
          exists: true,
          sprite: sprite.join('\n'),
          reaction
        }));
      }
      break;
    }

    case 'mute':
      if (!readSoul()) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        updateSoul({ muted: true });
        console.log(JSON.stringify({ action: 'muted' }));
      }
      break;

    case 'unmute':
      if (!readSoul()) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        updateSoul({ muted: false });
        console.log(JSON.stringify({ action: 'unmuted' }));
      }
      break;

    case 'off':
      if (!readSoul()) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        updateSoul({ hidden: true });
        console.log(JSON.stringify({ action: 'hidden' }));
      }
      break;

    // ─── New Commands: Mood, Feed, Pomodoro, Game, Streak, Achievements ──────

    case 'mood': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        const mood = soul.mood || 'content';
        const energy = soul.energy ?? 80;
        const moodEmojis = {
          happy: '😊', content: '🙂', bored: '😐', sad: '😢', excited: '🤩', grumpy: '😤'
        };
        const emoji = moodEmojis[mood] || '🙂';
        const energyBar = '█'.repeat(Math.round(energy / 10)) + '░'.repeat(10 - Math.round(energy / 10));
        console.log(JSON.stringify({
          action: 'mood',
          mood,
          energy,
          emoji,
          rendered: `${emoji} ${soul.name} is ${mood}\nEnergy: [${energyBar}] ${energy}%`,
          soul
        }));
      }
      break;
    }

    case 'feed': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        const newEnergy = Math.min(100, (soul.energy ?? 80) + 15);
        const feedCount = (soul.feedCount ?? 0) + 1;
        let newMood = soul.mood || 'content';
        if (newMood === 'sad' || newMood === 'bored') newMood = 'content';
        updateSoul({ energy: newEnergy, feedCount, mood: newMood, lastInteraction: Date.now() / 1000 });
        const reaction = await callBuddyReact(bones, soul, 'feed', '');
        console.log(JSON.stringify({
          action: 'feed',
          energy: newEnergy,
          feedCount,
          mood: newMood,
          reaction: reaction || '*nom nom nom* Thanks!',
          soul: { ...soul, energy: newEnergy, feedCount, mood: newMood }
        }));
      }
      break;
    }

    case 'pomodoro': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
        break;
      }
      const subCmd = args[1] || 'status';
      const pomoPath = join(homedir(), '.claude', 'buddy-pomodoro.json');

      function readPomo() {
        if (!existsSync(pomoPath)) return { phase: 'idle', startedAt: 0, completedPomodoros: 0 };
        try { return JSON.parse(readFileSync(pomoPath, 'utf-8')); } catch { return { phase: 'idle', startedAt: 0, completedPomodoros: 0 }; }
      }
      function writePomo(p) { writeFileSync(pomoPath, JSON.stringify(p, null, 2)); }

      const pomo = readPomo();
      if (subCmd === 'start') {
        pomo.phase = 'work';
        pomo.startedAt = Date.now();
        pomo.duration = 25 * 60 * 1000;
        writePomo(pomo);
        console.log(JSON.stringify({ action: 'pomodoro', status: 'started', phase: 'work', duration: '25:00' }));
      } else if (subCmd === 'stop') {
        pomo.phase = 'idle';
        writePomo(pomo);
        console.log(JSON.stringify({ action: 'pomodoro', status: 'stopped' }));
      } else {
        // status
        if (pomo.phase === 'idle') {
          console.log(JSON.stringify({ action: 'pomodoro', status: 'idle', completedPomodoros: pomo.completedPomodoros || 0 }));
        } else {
          const elapsed = Date.now() - pomo.startedAt;
          const remaining = Math.max(0, (pomo.duration || 25 * 60 * 1000) - elapsed);
          if (remaining <= 0) {
            // Pomodoro completed!
            pomo.phase = 'idle';
            pomo.completedPomodoros = (pomo.completedPomodoros || 0) + 1;
            writePomo(pomo);
            const statGrew = incrementStat('PATIENCE', 2);
            const statGrowth = statGrew > 0 ? { stat: 'PATIENCE', amount: statGrew } : null;
            console.log(JSON.stringify({
              action: 'pomodoro',
              status: 'completed',
              completedPomodoros: pomo.completedPomodoros,
              statGrowth
            }));
          } else {
            const mins = Math.floor(remaining / 60000);
            const secs = Math.floor((remaining % 60000) / 1000);
            console.log(JSON.stringify({
              action: 'pomodoro',
              status: 'running',
              phase: pomo.phase,
              remaining: `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`,
              completedPomodoros: pomo.completedPomodoros || 0
            }));
          }
        }
      }
      break;
    }

    case 'game': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        // Simple trivia via CLI
        const questions = [
          { q: 'What does HTTP stand for?', a: 'HyperText Transfer Protocol' },
          { q: 'Which port is HTTPS?', a: '443' },
          { q: 'What year was Python created?', a: '1991' },
          { q: 'What does API stand for?', a: 'Application Programming Interface' }
        ];
        const q = questions[Math.floor(Math.random() * questions.length)];
        const playCount = (soul.playCount ?? 0) + 1;
        const statGrew = incrementStat('CHAOS', 1);
        updateSoul({ playCount, lastInteraction: Date.now() / 1000 });
        const statGrowth = statGrew > 0 ? { stat: 'CHAOS', amount: statGrew } : null;
        console.log(JSON.stringify({
          action: 'game',
          type: 'trivia',
          question: q.q,
          answer: q.a,
          playCount,
          statGrowth,
          rendered: `🎮 Trivia!\n\nQ: ${q.q}\nA: ${q.a}`
        }));
      }
      break;
    }

    case 'streak': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        const streak = soul.streak ?? 0;
        const fire = streak >= 7 ? '🔥' : streak >= 3 ? '✨' : '';
        console.log(JSON.stringify({
          action: 'streak',
          streak,
          rendered: `${fire} Current streak: ${streak} day${streak !== 1 ? 's' : ''}`
        }));
      }
      break;
    }

    case 'achievements': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        const achievements = soul.achievements || [];
        const achieveNames = {
          'pet_10': '🐾 Pet Lover (10 pets)',
          'pet_100': '🐾 Pet Master (100 pets)',
          'feed_10': '🍽️ Good Caretaker (10 feeds)',
          'play_5': '🎮 Fun Times (5 games)',
          'streak_7': '🔥 Week Streak (7 days)',
          'streak_30': '🏆 Monthly Devotion (30 days)'
        };
        const list = achievements.map(a => achieveNames[a] || a);
        console.log(JSON.stringify({
          action: 'achievements',
          achievements,
          count: achievements.length,
          rendered: achievements.length > 0
            ? `🏆 Achievements (${achievements.length}):\n${list.join('\n')}`
            : '🏆 No achievements yet! Keep playing!'
        }));
      }
      break;
    }

    case 'eyes': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        const eye = args[1];
        if (!eye || eye === 'reset') {
          updateSoul({ customEye: null });
          console.log(JSON.stringify({ action: 'eyes_reset' }));
        } else {
          updateSoul({ customEye: eye });
          console.log(JSON.stringify({ action: 'eyes_set', eye }));
        }
      }
      break;
    }

    case 'hat': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        const hat = args[1];
        if (!hat || hat === 'reset') {
          updateSoul({ customHat: null });
          console.log(JSON.stringify({ action: 'hat_reset' }));
        } else {
          updateSoul({ customHat: hat });
          console.log(JSON.stringify({ action: 'hat_set', hat }));
        }
      }
      break;
    }

    case 'reroll': {
      const soul = readSoul();
      if (!soul) {
        console.log(JSON.stringify({ action: 'not_hatched' }));
      } else {
        // Generate a new random seed based on current time
        const newSeed = userId + '-reroll-' + Date.now();
        const newBones = generate(newSeed);

        // Create fresh soul — new egg, reset everything
        const newSoul = {
          name: newBones.name,
          personality: PERSONALITIES[newBones.species],
          hatchDate: new Date().toISOString().split('T')[0],
          muted: soul.muted,
          hidden: soul.hidden,
          language: soul.language,
          rerollSeed: newSeed,
          // Reset all progress
          mood: 'content',
          energy: 80,
          streak: 0,
          achievements: [],
          feedCount: 0,
          petCount: 0,
          playCount: 0,
          statBonuses: {},
          dailyStatGains: {},
          lastStatResetDate: null,
          lastInteraction: Date.now() / 1000
        };
        writeSoul(newSoul);
        const rendered = renderHatch(newBones, newSoul);
        const reaction = await callBuddyReact(newBones, newSoul, 'hatch', '');
        console.log(JSON.stringify({
          action: 'rerolled',
          bones: newBones,
          soul: newSoul,
          rendered,
          reaction,
          previousSpecies: bones.species,
          newSpecies: newBones.species
        }));
      }
      break;
    }

    case 'increment-stat': {
      // Called by hooks: node buddy.mjs increment-stat STAT_NAME amount
      const stat = args[1];
      const amount = parseInt(args[2], 10) || 1;
      if (!stat || !STAT_NAMES.includes(stat)) {
        console.log(JSON.stringify({ action: 'invalid_stat', stat }));
      } else {
        const grew = incrementStat(stat, amount);
        console.log(JSON.stringify({ action: 'stat_incremented', stat, requested: amount, actual: grew }));
      }
      break;
    }

    default:
      console.log(JSON.stringify({ action: 'unknown', command }));
  }
}

main();
