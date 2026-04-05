#!/usr/bin/env node
// Claude Code hook script for Buddy awareness
// Reads tool event from stdin, categorizes it, appends to buddy-events.json
// Also triggers stat growth based on coding activity

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

const EVENTS_PATH = join(homedir(), '.claude', 'buddy-events.json');
const SOUL_PATH = join(homedir(), '.claude', 'buddy.json');
const MAX_EVENTS = 50;
const DAILY_STAT_CAP = 5;

// Read stdin
let input = '';
try {
  input = readFileSync('/dev/stdin', 'utf8');
} catch {
  process.exit(0);
}

let event;
try {
  event = JSON.parse(input);
} catch {
  process.exit(0);
}

// Categorize the event
const category = categorize(event);
if (!category) process.exit(0);

// Build event record
const record = {
  category,
  detail: event.tool_name || event.session_id || '',
  timestamp: Date.now() / 1000,
};

// Read existing events
let events = [];
try {
  if (existsSync(EVENTS_PATH)) {
    events = JSON.parse(readFileSync(EVENTS_PATH, 'utf8'));
    if (!Array.isArray(events)) events = [];
  }
} catch {
  events = [];
}

// Append and trim to max
events.push(record);
if (events.length > MAX_EVENTS) {
  events = events.slice(-MAX_EVENTS);
}

// Write back
try {
  writeFileSync(EVENTS_PATH, JSON.stringify(events, null, 2));
} catch {
  // Silent fail
}

// ─── Stat Growth Triggers ───────────────────────────────────────────────────

const STAT_TRIGGERS = {
  git_commit:      { stat: 'DEBUGGING', amount: 1 },
  git_branch:      { stat: 'CHAOS',     amount: 1 },
  running_tests:   { stat: 'DEBUGGING', amount: 1 },
  building:        { stat: 'PATIENCE',  amount: 1 },
  writing_code:    { stat: 'WISDOM',    amount: 1 },
  session_start:   { stat: 'WISDOM',    amount: 1 },
};

const trigger = STAT_TRIGGERS[category];
if (trigger) {
  incrementStat(trigger.stat, trigger.amount);
}

// Track files modified for coding storm detection
if (category === 'writing_code') {
  trackFileModified(event);
}

// ─── Stat Growth System ─────────────────────────────────────────────────────

function incrementStat(stat, amount) {
  let soul;
  try {
    if (!existsSync(SOUL_PATH)) return 0;
    soul = JSON.parse(readFileSync(SOUL_PATH, 'utf-8'));
  } catch {
    return 0;
  }
  if (!soul || soul.muted || soul.hidden) return 0;

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

  try {
    writeFileSync(SOUL_PATH, JSON.stringify(soul, null, 2));
  } catch {
    return 0;
  }
  return allowed;
}

function trackFileModified(evt) {
  let soul;
  try {
    if (!existsSync(SOUL_PATH)) return;
    soul = JSON.parse(readFileSync(SOUL_PATH, 'utf-8'));
  } catch {
    return;
  }
  if (!soul) return;

  const today = new Date().toISOString().split('T')[0];
  if (soul.lastFileTrackDate !== today) {
    soul.dailyFilesModified = [];
    soul.lastFileTrackDate = today;
  }
  if (!soul.dailyFilesModified) soul.dailyFilesModified = [];

  const filePath = evt.tool_input?.file_path || evt.tool_input?.notebook_path || '';
  if (filePath && !soul.dailyFilesModified.includes(filePath)) {
    soul.dailyFilesModified.push(filePath);
    const count = soul.dailyFilesModified.length;

    try {
      writeFileSync(SOUL_PATH, JSON.stringify(soul, null, 2));
    } catch {
      return;
    }

    // Coding storm thresholds — trigger once per threshold per day
    if (count === 10) {
      incrementStat('PATIENCE', 2);
    } else if (count === 5) {
      incrementStat('PATIENCE', 1);
    }
  }
}

// ─── Event Categorization ───────────────────────────────────────────────────

function categorize(evt) {
  // Session lifecycle
  if (evt.event === 'session_start' || evt.hook_type === 'SessionStart') {
    return 'session_start';
  }
  if (evt.event === 'stop' || evt.hook_type === 'Stop') {
    return 'session_end';
  }

  // PostToolUse events
  const tool = evt.tool_name || '';

  // Bash commands — detect git, tests, builds
  if (tool === 'Bash') {
    const cmd = evt.tool_input?.command || '';
    if (/\bgit\s+commit\b/i.test(cmd)) {
      return 'git_commit';
    }
    if (/\bgit\s+(checkout|switch)\b/i.test(cmd)) {
      return 'git_branch';
    }
    if (/\b(test|jest|vitest|pytest|cargo test|go test|npm test|yarn test)\b/i.test(cmd)) {
      return 'running_tests';
    }
    if (/\b(build|make|cargo build|swift build|npm run build|tsc)\b/i.test(cmd)) {
      return 'building';
    }
    return 'running_command';
  }

  // File writing tools
  if (['Write', 'Edit', 'NotebookEdit'].includes(tool)) {
    return 'writing_code';
  }

  return null;
}
