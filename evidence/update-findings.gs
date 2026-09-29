const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';
const IMG = 'https://raw.githubusercontent.com/ahmedhany98/pulsepair/main/evidence/';
const DASH = 'https://dashboard.luciq.ai/applications/pulsepair/production';

const REMOVE_PREFIXES = [
  `Documented APIs don't compile`,
  `iOS masks nothing in screenshots`,
  `iOS has SessionReplay.sessionReplayLink`,
  `The dSYM upload script sends symbols`,
  `The AI guide's dSYM script`,
  `The dSYM upload script prints`,
  `The iOS SDK is a single 133 MB`,
  `The iOS AI Agent Integration Guide's`,
  `Every "See common-workflow.md" link`,
  `The luciq-setup skill says`,
  `The Jira issue has no Session Replay link`,
];

const TYPE_FIXES = { 'Bug/ confussion': 'Bug', 'Improvement': 'Feature request' };

const NEW_FINDINGS = [
  { type: 'Bug', img: ['d-replay-duration-zero.png'], links: [['Session Replay in Luciq', DASH + '/session-replay']],
    text: `Session Replay lists our sessions with a 0-second duration, including the session behind bug #2, which the bug itself says lasted 3 min 33 s. We can't tell from the list which replays are worth watching. Severity: Annoying · Impact: Would grumble.` },
  { type: 'Bug', img: ['d-adoption-200-percent.png'], links: [],
    text: `The release comparison says v1.1.0 reached 200% of our users (2 users out of 1 in total) and shows no first-seen date for v1.1.0 or v1.2.0. We can't trust it to tell whether a hotfix has rolled out. Severity: Painful · Impact: Would escalate.` },
  { type: 'Confusing UX', img: ['d-nonfatal-grouped-by-helper.png'], links: [],
    text: `The dashboard names our reporting helper (LuciqSetup.reportNonFatal) as the cause of our handled error instead of the line where it happened (ChaosActions.handledError), so every handled error we report through one helper would be grouped into a single issue. Severity: Painful · Impact: Would escalate.` },
  { type: 'Feature request', img: ['d-no-app-status-filter.png'], links: [],
    text: `The crash list can't be filtered by foreground or background; app status only appears as a breakdown inside a single crash. Slicing crashes by device, OS and foreground/background is exactly what we need. Severity: Painful · Impact: Would escalate.` },
];

const COMMENTS = {
  '4': { prefix: 'Patient identity, contact and billing fields are masked',
    text: `Patient identity, contact and billing fields are masked as private views in the bug screenshot and the replay; the rest of the screen stays readable. In the network log, Authorization and the login Set-Cookie show as *****. Where personal data still got through: before our fix, the login tokens (carrying email and name) leaked through Set-Cookie (finding {setcookie}); the Jira screenshot is a public link (finding {jirapublic}); and location (Cairo) is collected by default.` },
  '12': { prefix: 'Bug #2 was forwarded to Jira',
    text: `Bug #2 was forwarded to Jira (TEST-26129) without asking the tester anything: device (Simulator, iOS 26.2), app version, user, attributes, session profiler, screenshot and the last 10 steps arrived. Missing: a Session Replay link (finding {replay}), which we now attach as a user attribute, and the steps are unreadable for SwiftUI (finding {steps}). The screenshot is a public link, not a Jira attachment (finding {jirapublic}).` },
  '20': { prefix: 'Readable crash (HeartRateCalibration.offset',
    text: `Readable crash (HeartRateCalibration.offset, ChaosActions.swift:8, called from ChaosView.body) and app hang (ChaosActions.freeze, over 3 s). One SwiftUI view is masked with .luciq_privateView(). Repro steps and user steps don't name our SwiftUI screens or taps, even with LuciqTracedView (findings {steps} and {traced}).` },
};

const MARKERS = {
  setcookie: d => d.indexOf('Login tokens leave the device') === 0,
  jirapublic: d => d.indexOf('The screenshot bypasses our certified Jira') === 0,
  steps: d => d.indexOf('SwiftUI user steps are unreadable') === 0,
  traced: d => d.indexOf('The documented fix, LuciqTracedView') === 0,
  replay: d => d.toLowerCase().indexOf('session replay link') >= 0,
};

function updateFindings() {
  const doc = DocumentApp.openById(DOC_ID);
  const tables = doc.getBody().getTables();
  const log = [];
  const table = findTable(tables, t => headerRow(t, 'Type') >= 0);
  const start = headerRow(table, 'Type') + 1;

  for (let i = table.getNumRows() - 1; i >= start; i--) {
    const row = table.getRow(i);
    if (row.getNumCells() < 3) continue;
    const description = text(row.getCell(2));
    if (REMOVE_PREFIXES.some(p => description.indexOf(p) === 0)) {
      log.push('removed #' + text(row.getCell(0)) + ': ' + description.slice(0, 60));
      table.removeRow(i);
    }
  }

  for (let i = start; i < table.getNumRows(); i++) {
    const row = table.getRow(i);
    if (row.getNumCells() < 2) continue;
    const fixed = TYPE_FIXES[text(row.getCell(1))];
    if (fixed) {
      row.getCell(1).setText(fixed);
      log.push('type fixed on #' + text(row.getCell(0)) + ' -> ' + fixed);
    }
  }

  NEW_FINDINGS.forEach(f => {
    const marker = f.text.slice(0, 40);
    for (let i = start; i < table.getNumRows(); i++) {
      const row = table.getRow(i);
      if (row.getNumCells() > 2 && row.getCell(2).getText().indexOf(marker) >= 0) return;
    }
    const row = table.appendTableRow();
    ['', f.type, f.text, ''].forEach(v => row.appendTableCell(v));
    addEvidence(row.getCell(3), f.img, f.links, 220, log, 'new finding: ' + marker);
  });

  for (let i = start; i < table.getNumRows(); i++) {
    const cell = table.getRow(i).getCell(0);
    const n = String(i - start + 1);
    if (text(cell) !== n) cell.setText(n);
  }
  log.push('renumbered 1-' + (table.getNumRows() - start));

  const numbers = {};
  Object.keys(MARKERS).forEach(key => {
    for (let i = start; i < table.getNumRows(); i++) {
      const row = table.getRow(i);
      if (row.getNumCells() > 2 && MARKERS[key](text(row.getCell(2)))) {
        numbers[key] = text(row.getCell(0));
        return;
      }
    }
  });

  const missions = findTable(tables, t => t.getText().indexOf('Regression and hotfix') >= 0);
  for (let i = 0; i < missions.getNumRows(); i++) {
    const row = missions.getRow(i);
    if (row.getNumCells() < 3) continue;
    const key = (text(row.getCell(0)).match(/^M(\d+)\b/) || [])[1];
    const entry = key && COMMENTS[key];
    if (!entry || text(row.getCell(2)).indexOf(entry.prefix) !== 0) continue;
    row.getCell(2).setText(entry.text.replace(/\{(\w+)\}/g, (_, k) => '#' + (numbers[k] || '?')));
    log.push('comment updated: M' + key);
  }

  doc.saveAndClose();
  Logger.log(log.join('\n'));
}

function findTable(tables, pred) {
  const t = tables.find(pred);
  if (!t) throw new Error('Table not found');
  return t;
}

function headerRow(t, label) {
  for (let i = 0; i < t.getNumRows(); i++) {
    const row = t.getRow(i);
    if (row.getNumCells() > 1 && text(row.getCell(1)) === label) return i;
  }
  return -1;
}

function text(cell) {
  return cell.getText().replace(/\s+/g, ' ').trim();
}

function hasImage(cell) {
  return cell.findElement(DocumentApp.ElementType.INLINE_IMAGE) !== null;
}

function addEvidence(cell, images, links, width, log, where) {
  if (hasImage(cell)) return;
  const wasBlank = text(cell) === '';
  images.forEach(name => {
    try {
      const image = cell.appendImage(UrlFetchApp.fetch(IMG + name).getBlob());
      image.setHeight(Math.round(image.getHeight() * width / image.getWidth())).setWidth(width);
    } catch (e) {
      log.push('image failed ' + name + ': ' + e);
    }
  });
  links.forEach(([label, url]) => cell.appendParagraph(label).setLinkUrl(url));
  const first = cell.getChild(0);
  if (wasBlank && cell.getNumChildren() > 1 && first.getType() === DocumentApp.ElementType.PARAGRAPH &&
      first.asParagraph().getText() === '' && !first.asParagraph().findElement(DocumentApp.ElementType.INLINE_IMAGE)) {
    first.removeFromParent();
  }
  log.push('evidence: ' + where);
}
