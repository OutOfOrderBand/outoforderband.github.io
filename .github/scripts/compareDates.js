// .github/scripts/compareDates.js
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");
const cheerio = require("cheerio");

const DATA_FILE = path.join("data", "data.json");
const DIFF_FILE = path.join(".", "diff.txt");

// Canonicalize object keys and arrays for stable comparison
function canonicalize(obj) {
  if (Array.isArray(obj)) {
    return obj.map(canonicalize).sort();
  }
  if (obj && typeof obj === "object") {
    const keys = Object.keys(obj).sort();
    const out = {};
    for (const k of keys) out[k] = canonicalize(obj[k]);
    return out;
  }
  return obj;
}

// Load HTML from repo
function loadHtmlFromRepo() {
  const htmlPath = path.join("docs", "Dates.html");
  if (fs.existsSync(htmlPath)) {
    return fs.readFileSync(htmlPath, "utf8");
  }
  return null;
}

// Load HTML from URL (fallback)
function loadHtmlFromUrl(url) {
  try {
    return execSync(`curl -sL "${url}"`, {
      encoding: "utf8",
      maxBuffer: 10 * 1024 * 1024,
    });
  } catch (e) {
    console.error("Failed to fetch URL", e.message);
    return null;
  }
}

// Extract DATA object from HTML
function extractDataFromHtml(html) {
  const $ = cheerio.load(html);
  const scripts = $("script")
    .toArray()
    .map((s) => $(s).html())
    .filter(Boolean);

  for (const s of scripts) {
    const m = s.match(/(?:var\s+)?DATA\s*=\s*(\{[\s\S]*\});?/);
    if (m) {
      const jsonText = m[1];
      try {
        const cleaned = jsonText
          .replace(/(['"])?([a-zA-Z0-9_]+)\1\s*:/g, '"$2":')
          .replace(/,\s*}/g, "}")
          .replace(/,\s*]/g, "]");
        return JSON.parse(cleaned);
      } catch (e) {
        try {
          return eval("(" + jsonText + ")");
        } catch (err) {
          console.error("Failed to parse DATA JSON:", err.message);
        }
      }
    }
  }

  throw new Error("DATA object not found in HTML");
}

// Diff unavailable dates per band member
function diffUnavailable(oldObj, newObj) {
  const diff = {};

  for (const member of Object.keys(newObj)) {
    const oldDates = new Set(oldObj?.[member] || []);
    const newDates = new Set(newObj[member] || []);

    const added = [...newDates].filter((d) => !oldDates.has(d));
    const removed = [...oldDates].filter((d) => !newDates.has(d));

    if (added.length || removed.length) {
      diff[member] = { added, removed };
    }
  }

  return diff;
}

(async function main() {
  try {
    const pageUrl = process.env.PAGE_URL;
    const html = pageUrl ? loadHtmlFromUrl(pageUrl) : loadHtmlFromRepo();
    if (!html) throw new Error("No HTML source available");

    const rawData = extractDataFromHtml(html);

    // Extract unavailableDates object
    const newData = canonicalize(rawData.unavailableDates);

    // Load previous data.json
    let oldData = {};
    if (fs.existsSync(DATA_FILE)) {
      try {
        oldData = canonicalize(
          JSON.parse(fs.readFileSync(DATA_FILE, "utf8")).unavailableDates
        );
      } catch (e) {
        console.warn("Failed to parse existing data.json, treating as empty");
      }
    }

    // Compute diff
    const diff = diffUnavailable(oldData, newData);
    const changed = Object.keys(diff).length > 0;

    // Save updated data.json ONLY if changed
    if (changed) {
      fs.mkdirSync(path.dirname(DATA_FILE), { recursive: true });
      fs.writeFileSync(
        DATA_FILE,
        JSON.stringify({ unavailableDates: newData }, null, 2),
        "utf8"
      );
    }

    // Write human-readable diff.txt
    const lines = [];
    if (!changed) {
      lines.push("No changes detected.");
    } else {
      for (const member of Object.keys(diff)) {
        lines.push(`=== ${member} ===`);
        if (diff[member].added.length) {
          lines.push("Added:");
          diff[member].added.forEach((d) => lines.push(`  + ${d}`));
        }
        if (diff[member].removed.length) {
          lines.push("Removed:");
          diff[member].removed.forEach((d) => lines.push(`  - ${d}`));
        }
        lines.push("");
      }
    }

    fs.writeFileSync(DIFF_FILE, lines.join("\n"), "utf8");

    // Write structured diff.json for HTML email
    fs.writeFileSync("diff.json", JSON.stringify(diff, null, 2), "utf8");

    // Output for GitHub Actions (modern method)
    fs.appendFileSync(process.env.GITHUB_OUTPUT, `changed=${changed}\n`);

    process.exit(0);
  } catch (err) {
    console.error("Error in compareDates.js:", err);
    process.exit(2);
  }
})();
