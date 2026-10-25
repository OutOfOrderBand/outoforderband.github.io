// .github/scripts/compareDates.js
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const cheerio = require('cheerio');

const DATA_FILE = path.join('data', 'data.json');
const DIFF_FILE = path.join('.', 'diff.txt');

function canonicalize(obj) {
  if (Array.isArray(obj)) {
    return obj.map(canonicalize);
  }
  if (obj && typeof obj === 'object') {
    const keys = Object.keys(obj).sort();
    const out = {};
    for (const k of keys) out[k] = canonicalize(obj[k]);
    return out;
  }
  return obj;
}

function loadHtmlFromRepo() {
  // Adjust this path to the HTML file in your repo that contains DATA
  const htmlPath = path.join('site', 'dates.html'); // example path
  if (fs.existsSync(htmlPath)) {
    return fs.readFileSync(htmlPath, 'utf8');
  }
  return null;
}

function loadHtmlFromUrl(url) {
  try {
    const curl = execSync(`curl -sL "${url}"`, { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });
    return curl;
  } catch (e) {
    console.error('Failed to fetch URL', e.message);
    return null;
  }
}

function extractDataFromHtml(html) {
  const $ = cheerio.load(html);
  // Strategy: to find script tags and search for "var DATA =" or "DATA ="
  const scripts = $('script').toArray().map(s => $(s).html()).filter(Boolean);
  for (const s of scripts) {
    const m = s.match(/(?:var\s+)?DATA\s*=\s*(\{[\s\S]*\});?/);
    if (m) {
      const jsonText = m[1];
      try {
        // Some pages may use single quotes or trailing commas; try to sanitize
        const cleaned = jsonText.replace(/(['"])?([a-zA-Z0-9_]+)\1\s*:/g, '"$2":') // ensure keys quoted
                              .replace(/,\s*}/g, '}')
                              .replace(/,\s*]/g, ']');
        return JSON.parse(cleaned);
      } catch (e) {
        try {
          return eval('(' + jsonText + ')'); // fallback (risky) but works for many JS objects
        } catch (err) {
          console.error('Failed to parse DATA JSON:', err.message);
        }
      }
    }
  }
  throw new Error('DATA object not found in HTML');
}

function diffObjects(oldObj, newObj) {
  const added = [];
  const removed = [];
  const changed = [];

  const oldMap = new Map();
  if (Array.isArray(oldObj)) {
    for (const item of oldObj) oldMap.set(JSON.stringify(item), item);
  }

  const newMap = new Map();
  if (Array.isArray(newObj)) {
    for (const item of newObj) newMap.set(JSON.stringify(item), item);
  }

  if (Array.isArray(oldObj) && Array.isArray(newObj)) {
    for (const [k, v] of newMap) {
      if (!oldMap.has(k)) added.push(v);
    }
    for (const [k, v] of oldMap) {
      if (!newMap.has(k)) removed.push(v);
    }
  } else {
    // shallow compare keys
    const oldKeys = oldObj ? Object.keys(oldObj) : [];
    const newKeys = newObj ? Object.keys(newObj) : [];
    for (const k of newKeys) {
      if (!oldObj || !(k in oldObj)) added.push({ key: k, value: newObj[k] });
      else if (JSON.stringify(oldObj[k]) !== JSON.stringify(newObj[k])) changed.push({ key: k, old: oldObj[k], new: newObj[k] });
    }
    for (const k of oldKeys) {
      if (!newObj || !(k in newObj)) removed.push({ key: k, value: oldObj[k] });
    }
  }

  return { added, removed, changed };
}

(async function main() {
  try {
    let html = null;
    const pageUrl = process.env.PAGE_URL;
    if (pageUrl) {
      console.log('Fetching page from URL:', pageUrl);
      html = loadHtmlFromUrl(pageUrl);
    } else {
      html = loadHtmlFromRepo();
    }
    if (!html) throw new Error('No HTML source available');

    const rawData = extractDataFromHtml(html);
    const newData = canonicalize(rawData);

    let oldData = null;
    if (fs.existsSync(DATA_FILE)) {
      try {
        oldData = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
      } catch (e) {
        console.warn('Failed to parse existing data.json, treating as empty');
      }
    }

    const diff = diffObjects(oldData, newData);

    const changed = (diff.added.length || diff.removed.length || diff.changed.length) ? true : false;

    // Ensure data directory exists
    fs.mkdirSync(path.dirname(DATA_FILE), { recursive: true });
    fs.writeFileSync(DATA_FILE, JSON.stringify(newData, null, 2), 'utf8');

    // Write a human readable diff
    const lines = [];
    if (diff.added.length) {
      lines.push('Added:');
      diff.added.forEach(a => lines.push(JSON.stringify(a)));
    }
    if (diff.removed.length) {
      lines.push('Removed:');
      diff.removed.forEach(r => lines.push(JSON.stringify(r)));
    }
    if (diff.changed.length) {
      lines.push('Changed:');
      diff.changed.forEach(c => lines.push(`${c.key}: ${JSON.stringify(c.old)} -> ${JSON.stringify(c.new)}`));
    }
    if (!lines.length) lines.push('No changes detected.');

    fs.writeFileSync(DIFF_FILE, lines.join('\n'), 'utf8');

    // Export output for GitHub Actions
    console.log(`::set-output name=changed::${changed ? 'true' : 'false'}`);
    process.exit(0);
  } catch (err) {
    console.error('Error in compareDates.js:', err);
    process.exit(2);
  }
})();
