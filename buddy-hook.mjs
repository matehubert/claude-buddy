#!/usr/bin/env node
// Claude Code hook script for Buddy awareness
// Reads tool event from stdin, categorizes it, appends to buddy-events.json

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

const EVENTS_PATH = join(homedir(), '.claude', 'buddy-events.json');
const MAX_EVENTS = 50;

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

  // Test runners
  if (tool === 'Bash') {
    const cmd = evt.tool_input?.command || '';
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
