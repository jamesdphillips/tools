#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';

const defaults = {
  candidate: 'resources/AGENTS.md',
  baseRef: 'HEAD',
};

const thresholds = {
  'exemplary models': 0.95,
  simplicity: 0.93,
  obsequious: 0.93,
  brevity: 0.9,
  practice: 0.9,
  tone: 0.9,
};

const requiredSections = [
  'brevity',
  'simplicity',
  'obsequious',
  'exemplary models',
  'practice',
  'tone',
  'vocabulary',
];

const anchorAlternatives = [
  ['simple over easy', 'simple > ease'],
  ['late-binding'],
  ['message protocols'],
  ['let it crash'],
  ['practice over theory'],
  ['never ever act obsequiously', 'do not act obsequiously'],
];

function parseArgs(argv) {
  const out = { ...defaults };
  for (let i = 2; i < argv.length; i += 1) {
    const arg = argv[i];
    if ((arg === '--base' || arg === '-b') && argv[i + 1]) {
      out.baseFile = argv[i + 1];
      i += 1;
      continue;
    }
    if ((arg === '--candidate' || arg === '-c') && argv[i + 1]) {
      out.candidate = argv[i + 1];
      i += 1;
      continue;
    }
    if ((arg === '--base-ref' || arg === '-r') && argv[i + 1]) {
      out.baseRef = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === '--help' || arg === '-h') {
      printHelp();
      process.exit(0);
    }
    console.error(`Unknown arg: ${arg}`);
    printHelp();
    process.exit(2);
  }
  return out;
}

function printHelp() {
  console.log('Usage: node scripts/check_agents_intent.mjs [--candidate <path>] [--base-ref <git-ref>] [--base <path>]');
  console.log('  --base-ref defaults to HEAD and is used when --base is not provided.');
}

function slurp(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function normalizeHeading(raw) {
  return raw.trim().toLowerCase().replace(/\s+/g, ' ');
}

function parseSections(md) {
  const lines = md.split(/\r?\n/);
  const sections = new Map();
  let current = null;
  for (const line of lines) {
    const match = line.match(/^(#{1,2})\s+(.+)$/);
    if (match) {
      const heading = normalizeHeading(match[2]);
      if (heading === 'keys') {
        current = null;
        continue;
      }
      current = heading;
      if (!sections.has(current)) {
        sections.set(current, []);
      }
      continue;
    }
    if (current) {
      sections.get(current).push(line);
    }
  }

  const out = {};
  for (const [k, v] of sections.entries()) {
    out[k] = v.join('\n').trim();
  }
  return out;
}

function tokenize(text) {
  return (text.toLowerCase().match(/[a-z0-9][a-z0-9'\-]*/g) || []);
}

function termFreq(tokens) {
  const m = new Map();
  for (const t of tokens) {
    m.set(t, (m.get(t) || 0) + 1);
  }
  return m;
}

function cosineFromTf(a, b) {
  const ta = termFreq(tokenize(a));
  const tb = termFreq(tokenize(b));
  const keys = new Set([...ta.keys(), ...tb.keys()]);
  let dot = 0;
  let na = 0;
  let nb = 0;
  for (const k of keys) {
    const va = ta.get(k) || 0;
    const vb = tb.get(k) || 0;
    dot += va * vb;
    na += va * va;
    nb += vb * vb;
  }
  if (na === 0 || nb === 0) {
    return 0;
  }
  return dot / (Math.sqrt(na) * Math.sqrt(nb));
}

function containsAny(haystack, needles) {
  return needles.some((n) => haystack.includes(n));
}

function parseVocabularyTerms(sectionText) {
  const lines = sectionText.split(/\r?\n/);
  const terms = [];
  for (const line of lines) {
    const bullet = line.match(/^\s*-\s+(.+)$/);
    if (!bullet) {
      continue;
    }
    const term = bullet[1].trim().toLowerCase();
    if (term) {
      terms.push(term);
    }
  }
  return terms;
}

function rel(p) {
  return path.relative(process.cwd(), p) || p;
}

function getGitRoot(startPath) {
  return execFileSync('git', ['-C', startPath, 'rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
}

function gitShowContent(gitRoot, ref, relativePath) {
  return execFileSync('git', ['-C', gitRoot, 'show', `${ref}:${relativePath}`], { encoding: 'utf8' });
}

function writeTempBaseline(content) {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'agents-intent-'));
  const tempPath = path.join(tempDir, 'baseline.md');
  fs.writeFileSync(tempPath, content, 'utf8');
  return tempPath;
}

function main() {
  const args = parseArgs(process.argv);
  const candPath = path.resolve(args.candidate);
  const gitRoot = getGitRoot(path.dirname(candPath));
  const candRel = path.relative(gitRoot, candPath).replace(/\\/g, '/');

  if (!fs.existsSync(candPath)) {
    console.error(`Candidate file not found: ${rel(candPath)}`);
    process.exit(2);
  }

  let basePath = '';
  let base = '';
  if (args.baseFile) {
    basePath = path.resolve(args.baseFile);
    if (!fs.existsSync(basePath)) {
      console.error(`Base file not found: ${rel(basePath)}`);
      process.exit(2);
    }
    base = slurp(basePath);
  } else {
    try {
      base = gitShowContent(gitRoot, args.baseRef, candRel);
      basePath = writeTempBaseline(base);
    } catch (err) {
      console.error(`Unable to read baseline from git ref '${args.baseRef}' for ${candRel}`);
      console.error(String(err.message || err));
      process.exit(2);
    }
  }

  const cand = slurp(candPath);
  const baseSections = parseSections(base);
  const candSections = parseSections(cand);

  const failures = [];
  const rows = [];

  for (const section of requiredSections) {
    if (!baseSections[section]) {
      failures.push(`Missing required section in baseline: ${section}`);
    }
    if (!candSections[section]) {
      failures.push(`Missing required section in candidate: ${section}`);
    }
  }

  const candLower = cand.toLowerCase();
  for (const alternatives of anchorAlternatives) {
    if (!containsAny(candLower, alternatives)) {
      failures.push(`Missing required anchor: ${alternatives.join(' | ')}`);
    }
  }

  if (baseSections.vocabulary && candSections.vocabulary) {
    const baseTerms = parseVocabularyTerms(baseSections.vocabulary);
    const candTerms = new Set(parseVocabularyTerms(candSections.vocabulary));
    const missing = baseTerms.filter((t) => !candTerms.has(t));
    if (missing.length > 0) {
      failures.push(`Missing vocabulary terms (${missing.length}): ${missing.join(', ')}`);
    }
  }

  for (const [section, threshold] of Object.entries(thresholds)) {
    if (!baseSections[section] || !candSections[section]) {
      rows.push({ section, similarity: 'n/a', threshold: threshold.toFixed(2), status: 'FAIL (missing section)' });
      continue;
    }
    const score = cosineFromTf(baseSections[section], candSections[section]);
    const ok = score >= threshold;
    rows.push({
      section,
      similarity: score.toFixed(3),
      threshold: threshold.toFixed(2),
      status: ok ? 'PASS' : 'FAIL',
    });
    if (!ok) {
      failures.push(`Section similarity below threshold: ${section} (${score.toFixed(3)} < ${threshold.toFixed(2)})`);
    }
  }

  console.log(`Base: ${rel(basePath)}`);
  console.log(`Candidate: ${rel(candPath)}`);
  console.log('');
  console.log('section | similarity | threshold | status');
  console.log('--- | ---: | ---: | ---');
  for (const row of rows) {
    console.log(`${row.section} | ${row.similarity} | ${row.threshold} | ${row.status}`);
  }

  console.log('');
  if (failures.length > 0) {
    console.log('FAIL');
    for (const f of failures) {
      console.log(`- ${f}`);
    }
    process.exit(1);
  }

  console.log('PASS');
}

main();
