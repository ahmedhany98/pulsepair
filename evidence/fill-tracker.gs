const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';
const IMG = 'https://raw.githubusercontent.com/ahmedhany98/pulsepair/main/evidence/';
const DASH = 'https://dashboard.luciq.ai/applications/pulsepair/production';
const BUG1 = DASH + '/bugs/1';
const BUG2 = DASH + '/bugs/2';
const REPLAY2 = DASH + '/session-replay/1790677508683-2101639747';
const JIRA = 'https://instabug.atlassian.net/browse/TEST-26129';
const GUIDE = 'https://docs.luciq.ai/ios/setup-luciq-for-ios/integrate-luciq-on-ios/luciq-ai-ios-guide';
const COMMIT = 'https://github.com/ahmedhany98/pulsepair/commit/2d12cf8';
const FILL_VERDICT = false;

const FINDINGS = [
  { key: 'setcookie', type: 'Bug', img: ['f-setcookie-leak.png'], links: [['Bug #1 network log in Luciq', BUG1]],
    text: `Login tokens leave the device: the login response's Set-Cookie header was logged in clear in the bug's network log, and those tokens contain the patient's email and name, even though request masking was on. Steps: sign in, shake, send a bug, open its network log. Severity: Blocker · Impact: Would churn.` },
  { key: 'jirapublic', type: 'Bug', img: ['f-jira-public-screenshot.png'], links: [['Jira TEST-26129', JIRA]],
    text: `The screenshot bypasses our certified Jira: in the Jira issue it is a hotlinked public CloudFront URL valid until 2126, not a Jira attachment. Anyone with the link can open a patient screen outside Jira's access control. Severity: Blocker · Impact: Would churn.` },
  { key: 'black', type: 'Bug', img: ['bug1-black-screenshot.jpg'], links: [['Bug #1 in Luciq', BUG1]],
    text: `With screenshot masking on, the bug screenshot was completely black: the whole SwiftUI screen was hidden, not just patient data, so developers can't use it. Only fixable by masking text inputs and marking each patient field private. Severity: Painful · Impact: Would escalate.` },
  { key: 'steps', type: 'Bug', img: ['f-swiftui-steps-unreadable.png'], links: [['Bug #2 in Luciq', BUG2]],
    text: `SwiftUI user steps are unreadable: every tap is "Tap in _TtGC7SwiftUI15CellHostingView…" and every screen is "NavigationStackHostingController<AnyView>", and the same text lands in Jira. Developers still have to ask the tester what they did. Severity: Painful · Impact: Would churn.` },
  { key: 'traced', type: 'Bug', img: ['f-tracedview-no-effect.png'], links: [],
    text: `The documented fix, LuciqTracedView(name:), names neither crashes nor steps: after wrapping every screen, 2 of 2 crash occurrences and all user steps still say "NavigationStackHostingController<AnyView>". Severity: Painful · Impact: Would escalate.` },
  { key: 'attrs', type: 'Bug', img: ['f-attributes-missing.png'], links: [],
    text: `Michael Williams' crash arrived with no user attributes, while Emily Johnson's has plan and persona. The app sets both at every sign-in, so we can't slice his crash by build or role. Severity: Painful · Impact: Would escalate.` },
  { key: 'apinames', type: 'Doc gap', img: ['f-api-names-dont-compile.png'], links: [],
    text: `Documented APIs don't compile on SDK 19.11.0: the SwiftUI page's .Luciq_privateView() is really .luciq_privateView(), and the AI guide's Luciq.autoMaskSwiftUIViews is really autoMaskAllSwiftUIViews. Severity: Painful · Impact: Would escalate.` },
  { key: 'maskdefault', type: 'Confusing UX', img: ['f-ios-mask-default.png'], links: [['iOS AI Agent Integration Guide, Step 5', GUIDE]],
    text: `iOS masks nothing in screenshots by default (maskNothing), while Android masks everything. A healthcare app leaks patient data unless every team remembers to opt in. Severity: Painful · Impact: Would escalate.` },
  { key: 'noreplay', type: 'Feature request', img: ['f-jira-template.png'], links: [['Jira TEST-26129', JIRA]],
    text: `The Jira issue has no Session Replay link, only a link back to the bug, so developers can't watch what the tester did from Jira. We had to add it ourselves as a user attribute. Severity: Painful · Impact: Would escalate.` },
  { key: 'replaydoc', type: 'Doc gap', img: ['f-replay-link-undocumented.png'], links: [],
    text: `iOS has SessionReplay.sessionReplayLink in the SDK header, but the iOS docs never mention it; only KMP documents a replay link. Severity: Annoying · Impact: Would grumble.` },
  { key: 'domain', type: 'Doc gap', img: ['f-dsym-build-log.png'], links: [],
    text: `The dSYM upload script sends symbols to api.instabug.com, a domain no Luciq doc lists. Our firewall only allows listed vendor domains, so uploads would silently fail. Severity: Painful · Impact: Would escalate.` },
  { key: 'dsymdoc', type: 'Doc gap', img: ['f-dsym-doc-sample.png'], links: [['iOS AI Agent Integration Guide, Step 6', GUIDE]],
    text: `The AI guide's dSYM script exits with 1 and breaks the build when the upload script is missing, while the same page says to use exit 0. It also writes the app token in plain text into project.pbxproj, which the luciq-setup skill says never to do. Severity: Painful · Impact: Would escalate.` },
  { key: 'jiranet', type: 'Bug', img: ['f-jira-template.png'], links: [['Jira TEST-26129', JIRA]],
    text: `The Jira issue says "we are unable to capture your network requests automatically" although they were captured, and links to docs.instabug.com. Severity: Annoying · Impact: Would grumble.` },
  { key: 'jiratitle', type: 'Confusing UX', img: ['f-jira-template.png'], links: [['Jira TEST-26129', JIRA]],
    text: `The Jira issue title is "No description entered by the user.", which isn't acceptable as a title in our certified Jira. Severity: Annoying · Impact: Would grumble.` },
  { key: 'tokenlog', type: 'Bug', img: ['f-dsym-build-log.png'], links: [],
    text: `The dSYM upload script prints the full app token into the build log, so it ends up in our CI logs. Severity: Annoying · Impact: Would grumble.` },
  { key: 'sdktraffic', type: 'Bug', img: ['f-sdk-own-traffic.png'], links: [['Bug #1 network log in Luciq', BUG1]],
    text: `12 of the 16 calls in the bug's network log are Luciq's own traffic to api.instabug.com, with our app token in the URL, so our real calls get buried. Severity: Annoying · Impact: Would grumble.` },
  { key: 'nobodies', type: 'Bug', img: ['f-no-response-bodies.png'], links: [['Bug #2 network log in Luciq', BUG2]],
    text: `The network log records no response bodies for our API (every dummyjson response is empty), while Luciq's own calls show theirs, so developers can't see what the server returned. Severity: Annoying · Impact: Would escalate.` },
  { key: 'memory', type: 'Bug', img: ['f-jira-template.png'], links: [['Jira TEST-26129', JIRA]],
    text: `The session profiler in the Jira issue shows "Used Memory 100.0% - 0.04/0.04 GB", which is meaningless. Severity: Annoying · Impact: Would grumble.` },
  { key: 'swizzler', type: 'Confusing UX', img: ['f-ibgswizzler-frames.png'], links: [],
    text: `Every crash stack contains Luciq's own "IBGSwizzler+UIApplication.m" frames (the old Instabug name), so our developers will suspect the SDK caused the crash. Severity: Annoying · Impact: Would grumble.` },
  { key: 'size', type: 'Feature request', img: ['f-sdk-download-size.png'], links: [],
    text: `The iOS SDK is a single 133 MB download. Resolving it took 20+ minutes on our network and blocked the whole team's setup. We'd want a smaller or modular package. Severity: Annoying · Impact: Would grumble.` },
  { key: 'flutter', type: 'Doc gap', img: ['f-flutter-link.png'], links: [['iOS AI Agent Integration Guide', GUIDE]],
    text: `The iOS AI Agent Integration Guide's "iOS Screenshot Masking" link opens a Flutter page. Severity: Annoying · Impact: Would grumble.` },
  { key: 'broken404', type: 'Doc gap', img: ['doc-404-common-workflow.jpg'], links: [['Broken link', 'https://github.com/Instabug/luciq-docs/tree/main/ios/setup-luciq-for-ios/integrate-luciq-on-ios/common-workflow.md']],
    text: `Every "See common-workflow.md" link in the iOS AI Agent Integration Guide points to github.com/Instabug/luciq-docs and returns 404. Severity: Annoying · Impact: Would grumble.` },
  { key: 'pinning', type: 'Doc gap', img: ['f-spm-pin-conflict.png'], links: [],
    text: `The luciq-setup skill says to pin the SDK with upToNextMajorVersion, while the iOS AI guide says exact. Our change control needs one answer. Severity: Annoying · Impact: Would grumble.` },
  { key: 'tabbar', type: 'Confusing UX', img: ['bug2-patient-masked.jpg'], links: [['Bug #2 in Luciq', BUG2]],
    text: `The private-view mask for the Billing card is drawn over the tab bar, covering the Sensor and Sessions icons in the screenshot. Severity: Cosmetic · Impact: Wouldn't notice.` },
];

const CORE = {
  '14': { img: ['cp14-v110-sessions-avg-bpm.jpg'], links: [],
    text: `v1.1.0 (2) adds the average heart rate to session titles. Compared with v1.0 in Luciq: crash-free sessions 66.7% on 1.0.0 vs 0% on 1.1.0 (see M1).` },
  '15': { img: ['cp15-mcp-question.png'], links: [],
    text: `Asked "What's broken in PulsePair?" from Claude Code through the Luciq MCP server.` },
  '17': { img: ['cp14-v110-sessions-avg-bpm.jpg'], links: [],
    text: `Luciq themed to PulsePair red (Luciq.theme primaryColor) with our own prompt text: "Report a problem to the PulsePair QA team".` },
  '18': { img: ['bug2-patient-masked.jpg'], links: [['Bug #2 in Luciq', BUG2]],
    text: `Patient identity, contact and billing fields are private views and show black in screenshots; the password field is masked as a text input.` },
};

const MISSIONS = {
  '1': { img: ['m1-crash4-regression.png', 'm1-v120-no-crash.jpg'], links: [],
    text: `v1.1.0 (2) added the average heart rate to session titles and introduced a regression: saving without a paired sensor crashes (crash #4, "Division by zero" in SensorSimulator.averageBPM, SensorSimulator.swift:24). It hit 2 of 2 v1.1 sessions, so crash-free sessions fell to 0% from 66.7% on 1.0.0, for 2 users: Emily Johnson and Michael Williams (iOS 26.2, foreground). Hotfix v1.2.0 (3): the same action no longer crashes, and crash #4 appears only on 1.1.0 (2).` },
  '4': { img: ['bug2-patient-masked.jpg', 'm4-network-masked.png'], links: [['Bug #2 in Luciq', BUG2], ['Bug #2 session replay', REPLAY2]],
    text: `Patient identity, contact and billing fields are masked as private views in the bug screenshot and the replay; the rest of the screen stays readable. In the network log, Authorization and the login Set-Cookie show as *****. Where personal data still got through: before our fix, the login tokens (carrying email and name) leaked through Set-Cookie (finding {setcookie}); the Jira screenshot is a public link (finding {jirapublic}); and location (Cairo) is collected by default.` },
  '12': { img: ['f-jira-template.png'], links: [['Jira TEST-26129', JIRA]],
    text: `Bug #2 was forwarded to Jira (TEST-26129) without asking the tester anything: device (Simulator, iOS 26.2), app version, user, attributes, session profiler, screenshot and the last 10 steps arrived. Missing: a Session Replay link (finding {noreplay}), which we now attach as a user attribute, and the steps are unreadable for SwiftUI (finding {steps}). The screenshot is a public link, not a Jira attachment (finding {jirapublic}).` },
  '20': { img: ['m20-crash-and-hang.png', 'bug2-patient-masked.jpg'], links: [['Bug #2 in Luciq', BUG2]],
    text: `Readable crash (HeartRateCalibration.offset, ChaosActions.swift:8, called from ChaosView.body) and app hang (ChaosActions.freeze, over 3 s). One SwiftUI view is masked with .luciq_privateView(). Repro steps and user steps don't name our SwiftUI screens or taps, even with LuciqTracedView (findings {steps} and {traced}), and the documented SwiftUI APIs don't compile (finding {apinames}).` },
};

const VERDICT = [
  `We are the QA and verification lead at a medical-device company; our native iOS app pairs with Bluetooth heart-rate sensors.`,
  `We came with this pain: tickets arrive without the OS or device, so developers chase testers, with "missing context and rework even days later".`,
  `Luciq delivered this value: 2 of 2 bug reports reached Jira with OS, device, app version and user without asking the tester anything; a regression was pinned to v1.1.0 and 2 users within minutes and the hotfix confirmed; zero patient fields in screenshots after masking.`,
  `It almost lost us at: by default, login tokens were logged in clear; Jira received a public screenshot link that bypasses Jira's access control; SwiftUI steps are unreadable, so developers would still chase testers.`,
  `Our verdict: walk away for now. Every bug does land in Jira with device and OS, but the screenshot bypasses our certified Jira and the steps don't tell developers what happened. We'd buy for Test builds once screenshots are real Jira attachments and SwiftUI screens are named.`,
];

function fillTracker() {
  const doc = DocumentApp.openById(DOC_ID);
  const tables = doc.getBody().getTables();
  const log = [];
  const numbers = fillFindings(findTable(tables, t => headerRow(t, 'Type') >= 0), log);
  fillSetup(findTable(tables, t => t.getText().indexOf('Luciq dashboard link') >= 0), log);
  fillRows(findTable(tables, t => t.getText().indexOf('CATCH PROBLEMS') >= 0), CORE, c => c, 2, 3, numbers, log, 'Core Path ');
  fillRows(findTable(tables, t => t.getText().indexOf('Regression and hotfix') >= 0), MISSIONS, c => (c.match(/^M(\d+)\b/) || [])[1], 1, 2, numbers, log, 'M');
  if (FILL_VERDICT) fillVerdict(findTable(tables, t => headerRow(t, 'Line') >= 0), log);
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

function isBlank(cell) {
  return text(cell) === '' && !hasImage(cell);
}

function fill(template, numbers) {
  return template.replace(/\{(\w+)\}/g, (_, key) => '#' + (numbers[key] || '?'));
}

function setTextIfEmpty(cell, value, log, where) {
  if (text(cell) !== '') return;
  cell.setText(value);
  log.push('text: ' + where);
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

function fillFindings(table, log) {
  const start = headerRow(table, 'Type') + 1;
  const numbers = {};
  const pending = [];
  FINDINGS.forEach(f => {
    const marker = f.text.slice(0, 40);
    for (let i = start; i < table.getNumRows(); i++) {
      if (table.getRow(i).getNumCells() > 2 && table.getRow(i).getCell(2).getText().indexOf(marker) >= 0) {
        numbers[f.key] = text(table.getRow(i).getCell(0));
        return;
      }
    }
    pending.push(f);
  });
  for (let i = start; i < table.getNumRows() && pending.length; i++) {
    const row = table.getRow(i);
    if (row.getNumCells() < 4) continue;
    if (text(row.getCell(1)) === '' && text(row.getCell(2)) === '' && !hasImage(row.getCell(3))) {
      const f = pending.shift();
      fillFinding(row, f, log);
      numbers[f.key] = text(row.getCell(0)) || String(i - start + 1);
    }
  }
  let last = parseInt(text(table.getRow(table.getNumRows() - 1).getCell(0)), 10) || table.getNumRows() - start;
  pending.forEach(f => {
    const row = table.appendTableRow();
    last += 1;
    row.appendTableCell(String(last));
    row.appendTableCell('');
    row.appendTableCell('');
    row.appendTableCell('');
    fillFinding(row, f, log);
    numbers[f.key] = String(last);
  });
  return numbers;
}

function fillFinding(row, f, log) {
  const n = text(row.getCell(0));
  setTextIfEmpty(row.getCell(1), f.type, log, 'finding ' + n + ' type');
  setTextIfEmpty(row.getCell(2), f.text, log, 'finding ' + n + ' description');
  addEvidence(row.getCell(3), f.img, f.links, 220, log, 'finding ' + n);
}

function fillSetup(table, log) {
  for (let i = 0; i < table.getNumRows(); i++) {
    const row = table.getRow(i);
    if (row.getNumCells() < 2) continue;
    const label = text(row.getCell(0));
    const value = row.getCell(1);
    if (label.indexOf('Luciq dashboard link') >= 0 && text(value).indexOf('company-members') >= 0) {
      value.setText(DASH);
      value.editAsText().setLinkUrl(DASH);
      log.push('setup: dashboard link');
    }
    if (label.indexOf('Integrated Luciq with AI') >= 0) {
      if (text(value).indexOf('Yes or no') >= 0) value.setText('Yes');
      setTextIfEmpty(value, 'Yes', log, 'setup: AI answer');
      addEvidence(value, ['ai-setup-claude-code.png'], [['Commit: Luciq SDK added by Claude Code', COMMIT]], 320, log, 'setup: AI evidence');
    }
  }
}

function fillRows(table, entries, keyOf, shotCol, commentCol, numbers, log, prefix) {
  for (let i = 0; i < table.getNumRows(); i++) {
    const row = table.getRow(i);
    if (row.getNumCells() <= commentCol) continue;
    const key = keyOf(text(row.getCell(0)));
    const entry = key && entries[key];
    if (!entry) continue;
    addEvidence(row.getCell(shotCol), entry.img, entry.links, 200, log, prefix + key);
    setTextIfEmpty(row.getCell(commentCol), fill(entry.text, numbers), log, prefix + key + ' comment');
  }
}

function fillVerdict(table, log) {
  for (let i = 0; i < table.getNumRows(); i++) {
    const row = table.getRow(i);
    const n = parseInt(text(row.getCell(0)), 10);
    if (n >= 1 && n <= 5 && row.getNumCells() > 2) setTextIfEmpty(row.getCell(2), VERDICT[n - 1], log, 'verdict ' + n);
  }
}
