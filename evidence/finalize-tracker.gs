const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';
const JIRA_RETEST = 'https://instabug.atlassian.net/browse/TEST-26143';
const FILL_VERDICT = true;

const MARKERS = {
  jirapublic: d => d.indexOf('The Jira issue shows the screenshot through a signed') === 0,
  steps: d => d.indexOf('SwiftUI user steps are unreadable') === 0,
  traced: d => d.indexOf('The documented fix, LuciqTracedView') === 0,
  replay: d => d.toLowerCase().indexOf('session replay link') >= 0,
};

const COMMENTS = {
  '4': { prefix: 'Patient identity, contact and billing fields are masked',
    text: `Patient identity, contact and billing fields are masked as private views in the bug screenshot and the replay; the rest of the screen stays readable. In the network log, Authorization and the login Set-Cookie show as *****. Extra credit, where personal data still gets through: the Jira screenshot is a signed link valid for 100 years, outside Jira's access control (finding {jirapublic}), and location (Cairo) is collected by default.` },
  '12': { prefix: 'Bug #2 was forwarded to Jira',
    text: `Bug #6 reached our Jira (TEST-26143) nine seconds after it was reported, without asking the tester anything: device (Simulator, iOS 26.2), app version 1.2.0 (3), user, attributes, session profiler, screenshot, the last 10 steps and a Session Replay link, which we add to every report with one line of code (SessionReplay.sessionReplayLink as a user attribute). Out of the box the replay link is missing (finding {replay}), SwiftUI steps are unreadable (finding {steps}), and the screenshot is a long-lived signed link, not a Jira attachment (finding {jirapublic}).` },
  '20': { prefix: 'Readable crash (HeartRateCalibration.offset',
    text: `Readable crash (HeartRateCalibration.offset, ChaosActions.swift:8, called from ChaosView.body) and app hang (ChaosActions.freeze, over 3 s). One SwiftUI view is masked with .luciq_privateView(). Checked whether repro steps and user steps name our SwiftUI screens and taps: they don't, even with LuciqTracedView (findings {steps} and {traced}).` },
};

const VERDICT = [
  `We are the QA and verification lead at a medical-device company; our native iOS app pairs with Bluetooth heart-rate sensors.`,
  `We came with this pain: tickets arrive without the OS or device, so developers chase testers, with "missing context and rework even days later".`,
  `Luciq delivered this value: 2 of 2 bugs we forwarded reached our Jira with OS, device, app version and user without asking the tester a single question, plus a Session Replay link once we added one line of code; crashes can be sliced by device, OS and foreground/background; a v1.1 regression was pinned to 1.1.0 and its 2 users within minutes, and the hotfix confirmed.`,
  `It almost lost us at: the screenshot in Jira is a signed link valid for 100 years, which bypasses our certified Jira's access control; and SwiftUI steps arrive unreadable, so developers would still have to ask testers what they did.`,
  `Our verdict: buy for our test environments, on two conditions: screenshots must arrive in Jira as real attachments, and SwiftUI steps must be readable out of the box. Until then, nothing goes into production.`,
];

function finalizeTracker() {
  const doc = DocumentApp.openById(DOC_ID);
  const tables = doc.getBody().getTables();
  const log = [];

  const findings = findTable(tables, t => headerRow(t, 'Type') >= 0);
  const start = headerRow(findings, 'Type') + 1;
  const numbers = {};
  for (let i = start; i < findings.getNumRows(); i++) {
    const row = findings.getRow(i);
    if (row.getNumCells() < 3) continue;
    if (text(row.getCell(1)) === 'Feature') {
      row.getCell(1).setText('Feature request');
      log.push('type fixed on #' + text(row.getCell(0)));
    }
    const description = text(row.getCell(2));
    Object.keys(MARKERS).forEach(key => {
      if (!numbers[key] && MARKERS[key](description)) numbers[key] = text(row.getCell(0));
    });
  }

  const missions = findTable(tables, t => t.getText().indexOf('Regression and hotfix') >= 0);
  for (let i = 0; i < missions.getNumRows(); i++) {
    const row = missions.getRow(i);
    if (row.getNumCells() < 3) continue;
    const key = (text(row.getCell(0)).match(/^M(\d+)\b/) || [])[1];
    const entry = key && COMMENTS[key];
    if (!entry) continue;
    const current = text(row.getCell(2));
    if (current.indexOf(entry.prefix) === 0 || (key === '12' && current.indexOf('Bug #6 reached our Jira') === 0)) {
      row.getCell(2).setText(entry.text.replace(/\{(\w+)\}/g, (_, k) => '#' + (numbers[k] || '?')));
      log.push('comment updated: M' + key);
    }
    if (key === '12' && row.getCell(1).getText().indexOf('TEST-26143') < 0) {
      row.getCell(1).appendParagraph('Jira TEST-26143 (with Session Replay link)').setLinkUrl(JIRA_RETEST);
      log.push('evidence: M12 retest link');
    }
  }

  if (FILL_VERDICT) {
    const verdict = findTable(tables, t => headerRow(t, 'Line') >= 0);
    for (let i = 0; i < verdict.getNumRows(); i++) {
      const row = verdict.getRow(i);
      const n = parseInt(text(row.getCell(0)), 10);
      if (n >= 1 && n <= 5 && row.getNumCells() > 2 && text(row.getCell(2)) === '') {
        row.getCell(2).setText(VERDICT[n - 1]);
        log.push('verdict line ' + n);
      }
    }
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
