const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';
const IMG = 'https://raw.githubusercontent.com/ahmedhany98/pulsepair/main/evidence/';
const DASH = 'https://dashboard.luciq.ai/applications/pulsepair/production';
const ALERT_DOCS = 'https://docs.luciq.ai/product-guides-and-integrations/product-guides/automation-and-workflows/alerts-and-rules/';

const NEW_FINDINGS = [
  { type: 'Bug', img: 'f-regression-no-alert.png', label: 'Steps to reproduce:',
    text: `Luciq's default stability alerts never caught our v1.1 regression. Crash #4 (Division by zero) crashed 2 of the first 3 sessions on 1.1.0 (2) at 13:35, and 1.0.0 (1), which carries half our sessions, has stayed at or below 96% crash-free since crash #3 hit it twice. Three default rules exist for exactly this and have been on since 12:19: "A crash affects at least 1% of an app version's sessions in the last 24 hours", "Crash-free sessions less than 99.0% within 24 hours" and "Crash-free users less than 99.0% within 24 hours". All three have fired 0 times; only our generic "Crash occurred" rule reacted (finding #20). All three watch only "Latest release, Top releases", and Luciq marks none of our versions as a top release, so they most likely only ever checked the hotfix 1.2.0 (3), which is 100% crash-free on 5 sessions. The docs never say what makes a release a top release. Severity: Painful · Impact: Would escalate.`,
    steps: [
      `In the PulsePair dashboard, open Alerts & Rules and open the three default rules above. Each is limited to "App version is one of Latest release, Top releases" and has never triggered.`,
      `Open crash #4: 2 occurrences from 2 users, only on 1.1.0 (2), at 13:35:00 and 13:35:21.`,
      `Open Session Replay and filter App version to 1.1.0 (2). The three oldest sessions start between 13:34 and 13:35, and two of them end in a crash.`,
      `Compare crash-free sessions per version: 1.0.0 (1) is at 96.0% and 1.1.0 (2) at 95.3%, both under 99%; 1.2.0 (3) is at 100% on 5 sessions.`,
      `Open Triggered alerts: none of the three rules has an incident.`,
    ],
    links: [
      ['Crash #4 (1.1.0 regression)', DASH + '/crashes/4'],
      ['Crash #3 (1.0.0)', DASH + '/crashes/3'],
      ['First 1.1.0 (2) session, ends in a crash', DASH + '/session-replay/1790678058815-1872208715'],
      ['Docs: predefined alerts', ALERT_DOCS + 'predefined-alerts'],
    ] },
  { type: 'Bug', img: 'f-release-order.png', label: 'Steps to reproduce:',
    text: `Luciq dates our releases out of order. We shipped 1.0.0 (1), then 1.1.0 (2) with a crash, then the hotfix 1.2.0 (3). Luciq's release data, which we read through the Luciq MCP, says 1.1.0 (2) was first seen at 13:42:27, yet its first session started at 13:34:19, crash #4 hit it at 13:35:00, and none of its 43 sessions started at 13:42. The hotfix is dated 13:40:23, two minutes before the build it fixed, so Luciq lists 1.1.0 (2) as our most recent release, above the fix. Our App Store isn't connected, so these dates come only from our own sessions. For a regulated team the release timeline is audit evidence of which build was live when a defect appeared. Severity: Painful · Impact: Would escalate.`,
    steps: [
      `Open crash #4: it affects only 1.1.0 (2), first at 13:35:00.`,
      `Open Session Replay, filter App version to 1.1.0 (2) and scroll to the oldest session: it starts at 13:34:19 and ends in a crash.`,
      `Do the same for 1.2.0 (3): its oldest session starts at 13:37:16.`,
      `Ask the Luciq MCP when each version was first seen (app_version_adoption): 1.0.0 (1) 10:00:24, 1.2.0 (3) 10:40:23 and 1.1.0 (2) 10:42:27 UTC, which is 13:00, 13:40 and 13:42 in Cairo.`,
      `Ask it for our most recent releases without naming a version: 1.1.0 (2) comes first, above the hotfix.`,
    ],
    links: [
      ['Crash #4 (1.1.0 (2) only)', DASH + '/crashes/4'],
      ['First 1.1.0 (2) session, 13:34:19', DASH + '/session-replay/1790678058815-1872208715'],
      ['First 1.2.0 (3) session, 13:37:16', DASH + '/session-replay/1790678236337-2324976016'],
    ] },
  { type: 'Bug', img: 'f-nonfatal-message-lost.png', label: 'Steps to reproduce:',
    text: `When we report a handled error, Luciq drops its message. Our sensor check throws a Swift error that says "Sensor reported an impossible heart rate of 412 bpm." and we report it with CrashReporting.error(error).report() on SDK 19.11.0. Non-fatals #5 (iPhone 15) and #1 (simulator) show only "PulsePair.SensorReadingError" as the title, exception name and exception message, and the heart-rate text appears nowhere in the occurrence or its logs. A tester can't tell what went wrong without reading our code, and the "Exception message" condition in crash alert rules can only match the type name. The docs' error examples only use an NSError with no description and never say what the dashboard shows as the message. Severity: Painful · Impact: Would escalate.`,
    steps: [
      `In PulsePair, open the Chaos tab and tap Handled error. The app shows "Caught and reported as non-fatal: Sensor reported an impossible heart rate of 412 bpm."`,
      `In Luciq, open Crashes, filter by Non-fatal and open crash #5.`,
      `Read the title and the exception message: both say "PulsePair.SensorReadingError", with no heart-rate text.`,
      `Open the occurrence's logs and search for "heart rate": no matches.`,
      `Open crash #1: the same on the simulator.`,
    ],
    links: [
      ['Non-fatal #5 (iPhone 15)', DASH + '/crashes/5'],
      ['Non-fatal #1 (simulator)', DASH + '/crashes/1'],
      ['Docs: iOS reporting crashes', 'https://docs.luciq.ai/ios/setup-luciq-for-ios/setup-crash-reporting/reporting-crashes'],
    ] },
  { type: 'Feature request', img: 'f-apm-alerts-no-device.png', label: 'How to see it:',
    text: `We want Device and OS conditions on performance alert rules, as crash rules already have. App launch, Screen loading, Network, Flows and Screen rendering rules only offer app version, launch type or trace name, method (network only), key metric and count, and Luciq's docs list the same set. At 15:30 our "App launch" rule opened an incident (cold launch Apdex 0.24, threshold 0.85) and emailed 7 of us. 50 of today's 59 cold launches came from simulator debug builds (Apdex 0.12, median 3.65 s); our real iPhone 15 had 9 (median 290 ms). The rule only fires above 50 launches, so the simulators tipped it over, and app version can't separate them: 22 simulator launches ran the same 1.0.0 (1) build as the iPhone. Today we'd have to live with the noise, mute launch alerts for real phones too, or move debug builds to a separate app mode. Severity: Painful · Impact: Would escalate.`,
    steps: [
      `In the PulsePair dashboard, open Alerts & Rules, click Create and pick App launches.`,
      `Click Add conditions: only App version, Launch type, Key metric and Count are offered. Screen loading, Network and Flows are the same.`,
      `Switch to Crashes and click Add conditions: Device, OS and App status are offered. Close without saving.`,
      `Open Triggered alerts and select "Apdex less than 0.85 within 1 day" (Cold app launch, last Apdex 0.24).`,
      `Open APM, App launch, Cold app launch and filter by device: Simulator has 50 launches at Apdex 0.12, iPhone 15 has 9 at 0.67.`,
    ],
    links: [
      ['Docs: alerting for performance metrics', ALERT_DOCS + 'alerting-for-performance-metrics'],
      ['Luciq APM for PulsePair', DASH],
    ] },
];

const EXISTING = [
  { prefixes: ['The Jira issue shows the screenshot through a signed', 'Besides attaching the screenshot'],
    fixes: [
      ['The Jira issue shows the screenshot through a signed CloudFront link that stays valid for 100 years (until 2126) instead of a Jira attachment,',
       'Besides attaching the screenshot, the Jira issue embeds it in the description through a signed CloudFront link that stays valid for 100 years (until 2126),'],
      ['expire the same day', 'expire within an hour'],
    ],
    steps: [
      `With Jira connected and auto-forwarding on, report a bug with a screenshot from PulsePair. Bug #2 became TEST-26129.`,
      `Open the Jira issue. The screenshot is attached (45500824.png) and also embedded in the description.`,
      `Copy the embedded image's address: it points at d38gnqwzxziyyy.cloudfront.net with Expires=4946351416, which is 29 Sep 2126.`,
      `Open that address in a private window with no Jira or Luciq login: the screenshot loads.`,
      `Open the same bug in the Luciq dashboard and copy its screenshot link: it expires within an hour.`,
    ] },
  { prefixes: ['Michael Williams'],
    fixes: [['by build or role', 'by plan or persona']],
    steps: [
      `On a simulator running PulsePair 1.1.0 (2), sign in as emilys / emilyspass, open Sessions and tap Save session without pairing a sensor. The app crashes.`,
      `Relaunch the app without tapping Sign out, sign in as michaelw / michaelwpass and trigger the same crash within about 15 seconds.`,
      `Relaunch the app so the crash uploads.`,
      `In Luciq, open crash #4 and compare the two occurrences' user attributes: Emily's has plan and persona, Michael's has none.`,
    ] },
  { prefixes: ['Auto-forwarding created the Jira issue'],
    fixes: [['about 47 seconds after the report, before the network log had uploaded,',
             'without the network log (47 seconds after bug #2 was reported, and 9 seconds after bug #6),']],
    steps: [
      `With Jira connected and auto-forwarding on, sign in to PulsePair so it makes API calls, then shake and send a bug report.`,
      `In Luciq, open the bug's Network log: the requests are there.`,
      `Open the Jira issue Luciq created. Bug #2 became TEST-26129 47 seconds after the report; bug #6 became TEST-26143 after 9 seconds.`,
      `Under "Looking for More Details?", item 1 says "we are unable to capture your network requests automatically" and links to docs.instabug.com.`,
      `Reopen the issue hours later: the text is unchanged.`,
    ] },
  { prefixes: ['When the app has no sessions in the selected range'],
    fixes: [],
    steps: [
      `Open PulsePair (production) in the Luciq dashboard and go to App Health.`,
      `Set the date range to a day with no sessions, for example 27 Sep 2026 (our first session was on 29 Sep).`,
      `The Frustration-free sessions card says "Based on 0 sessions" but shows 0% rated Unacceptable.`,
      `Switch the range to 29 Sep: the card shows a real score.`,
    ] },
];

const TEXT_FIXES = [
  { where: 'M12', table: t => t.getText().indexOf('Regression and hotfix') >= 0,
    from: 'the screenshot is a long-lived signed link, not a Jira attachment (finding #8)',
    to: 'the screenshot, although attached, is also embedded through a 100-year signed link that opens outside Jira (finding #8)' },
  { where: 'verdict', table: t => headerRow(t, 'Line') >= 0,
    from: 'Screenshots arrive in Jira as real attachments.',
    to: 'Screenshots reach Jira only as attachments, never through public links.' },
];

function addFindings() {
  const doc = DocumentApp.openById(DOC_ID);
  const tables = doc.getBody().getTables();
  const log = [];
  const table = findTable(tables, t => headerRow(t, 'Type') >= 0);
  const start = headerRow(table, 'Type') + 1;

  EXISTING.forEach(e => {
    for (let i = start; i < table.getNumRows(); i++) {
      const row = table.getRow(i);
      if (row.getNumCells() < 3) continue;
      const cell = row.getCell(2);
      if (!e.prefixes.some(p => text(cell).indexOf(p) === 0)) continue;
      const n = text(row.getCell(0));
      e.fixes.forEach(([from, to]) => replaceSpan(cell, from, to, log, '#' + n));
      if (cell.getText().indexOf('Steps to reproduce') >= 0) return;
      insertSteps(cell, descriptionIndex(cell, e.prefixes) + 1, 'Steps to reproduce:', e.steps, styleOf(cell));
      log.push('steps added: #' + n);
      return;
    }
    log.push('NOT FOUND: row starting ' + e.prefixes[0]);
  });

  let blank = table.getNumRows();
  while (blank - 1 >= start && isBlank(table.getRow(blank - 1))) blank--;
  if (blank === table.getNumRows()) {
    const row = table.appendTableRow();
    for (let c = 0; c < 4; c++) row.appendTableCell('');
  }
  const template = table.getRow(blank);
  const style = styleOf(table.getRow(blank - 1).getCell(2));

  NEW_FINDINGS.forEach(f => {
    const marker = f.text.slice(0, 45);
    for (let i = start; i < table.getNumRows(); i++) {
      const row = table.getRow(i);
      if (row.getNumCells() > 2 && row.getCell(2).getText().indexOf(marker) >= 0) {
        log.push('already there: #' + text(row.getCell(0)));
        return;
      }
    }
    const above = parseInt(text(table.getRow(blank - 1).getCell(0)), 10);
    const n = String(isNaN(above) ? blank - start + 1 : above + 1);
    const row = table.insertTableRow(blank, template.copy());
    blank++;
    row.getCell(0).setText(n);
    row.getCell(1).setText(f.type);
    const cell = row.getCell(2);
    cell.setText(f.text);
    applyStyle(cell.editAsText(), style, false);
    insertSteps(cell, 1, f.label, f.steps, style);
    addEvidence(row.getCell(3), [f.img], f.links, 220, log, '#' + n);
    log.push('added #' + n + ' (' + f.type + '): ' + marker);
  });

  TEXT_FIXES.forEach(fix => {
    const t = tables.find(fix.table);
    if (!t) { log.push('NOT FOUND: table for ' + fix.where); return; }
    replaceSpan(t, fix.from, fix.to, log, fix.where);
  });

  doc.saveAndClose();
  Logger.log(log.join('\n'));
}

function replaceSpan(element, from, to, log, where) {
  const t = element.editAsText();
  const i = t.getText().indexOf(from);
  if (i < 0) {
    if (t.getText().indexOf(to) < 0) log.push('NOT FOUND in ' + where + ': ' + from.slice(0, 60));
    return;
  }
  t.insertText(i + from.length, to);
  t.deleteText(i, i + from.length - 1);
  log.push('fixed ' + where + ': ' + to.slice(0, 60));
}

function descriptionIndex(cell, prefixes) {
  for (let i = 0; i < cell.getNumChildren(); i++) {
    const block = asBlock(cell.getChild(i));
    if (block && prefixes.some(p => block.getText().replace(/\s+/g, ' ').trim().indexOf(p) === 0)) return i;
  }
  return 0;
}

function asBlock(element) {
  const type = element.getType();
  if (type === DocumentApp.ElementType.PARAGRAPH) return element.asParagraph();
  if (type === DocumentApp.ElementType.LIST_ITEM) return element.asListItem();
  return null;
}

function insertSteps(cell, index, label, steps, style) {
  const first = asBlock(cell.getChild(0));
  const alignment = first && first.getAlignment();
  [label].concat(steps.map((s, k) => (k + 1) + '. ' + s)).forEach((line, k) => {
    const p = cell.insertParagraph(index + k, line);
    if (alignment) p.setAlignment(alignment);
    applyStyle(p.editAsText(), style, k === 0);
  });
}

function styleOf(cell) {
  const t = cell.editAsText();
  return { size: t.getFontSize(0), font: t.getFontFamily(0), color: t.getForegroundColor(0) };
}

function applyStyle(t, style, bold) {
  t.setLinkUrl(null);
  t.setBold(bold);
  t.setItalic(false);
  if (style.size) t.setFontSize(style.size);
  if (style.font) t.setFontFamily(style.font);
  if (style.color) t.setForegroundColor(style.color);
}

function isBlank(row) {
  for (let c = 0; c < row.getNumCells(); c++) {
    if (text(row.getCell(c)) !== '' || hasImage(row.getCell(c))) return false;
  }
  return true;
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
