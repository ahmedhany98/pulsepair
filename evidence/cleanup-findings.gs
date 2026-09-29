const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';

const REMOVE_PREFIXES = [
  `Login tokens leave the device`,
  `With screenshot masking on, the bug screenshot was completely black`,
  `The Jira issue title is`,
  `The session profiler in the Jira issue shows`,
  `Every crash stack contains Luciq's own`,
  `The private-view mask for the Billing card`,
  `Session Replay lists our sessions with a 0-second`,
  `The dashboard names our reporting helper`,
];

const REWORDS = [
  { prefix: `The screenshot bypasses our certified Jira`, type: 'Bug',
    text: `The Jira issue shows the screenshot through a signed CloudFront link that stays valid for 100 years (until 2126) instead of a Jira attachment, so anyone who gets the link can open the patient screen outside Jira's access control, while Luciq's own links to the same screenshot expire the same day. Severity: Blocker · Impact: Would churn.` },
  { prefix: `SwiftUI user steps are unreadable`, type: 'Confusing UX',
    text: `SwiftUI user steps are unreadable by default: taps show SwiftUI's internal class names ("Tap in _TtGC7SwiftUI15CellHostingView…") and every screen is "NavigationStackHostingController<AnyView>", and the same text lands in Jira. Readable steps need the separate LuciqSwiftUIIntegrator build phase or manual UserStep calls, which the setup guide never points SwiftUI apps to. Severity: Painful · Impact: Would churn.` },
  { prefix: `The Jira issue says "we are unable`, type: 'Bug',
    text: `Auto-forwarding created the Jira issue about 47 seconds after the report, before the network log had uploaded, so the issue wrongly says "we are unable to capture your network requests automatically" and links to the old docs.instabug.com, even though the bug has a network log in Luciq. Severity: Annoying · Impact: Would grumble.` },
  { prefix: `The network log records no response bodies`, type: 'Bug',
    text: `The network log shows no request or response bodies for any of our API calls (for example the login POST and the patient profile GET), while Luciq's own calls show theirs, so developers can't see what was sent or returned. Severity: Painful · Impact: Would escalate.` },
];

const MARKERS = {
  jirapublic: d => d.indexOf('The Jira issue shows the screenshot through a signed') === 0,
  steps: d => d.indexOf('SwiftUI user steps are unreadable') === 0,
  traced: d => d.indexOf('The documented fix, LuciqTracedView') === 0,
  replay: d => d.toLowerCase().indexOf('session replay link') >= 0,
};

const COMMENTS = {
  '4': { prefix: 'Patient identity, contact and billing fields are masked',
    text: `Patient identity, contact and billing fields are masked as private views in the bug screenshot and the replay; the rest of the screen stays readable. In the network log, Authorization and the login Set-Cookie show as *****. Where personal data still gets through: the Jira screenshot is a signed link valid for 100 years, outside Jira's access control (finding {jirapublic}), and location (Cairo) is collected by default.` },
  '12': { prefix: 'Bug #2 was forwarded to Jira',
    text: `Bug #2 was forwarded to Jira (TEST-26129) without asking the tester anything: device (Simulator, iOS 26.2), app version, user, attributes, session profiler, screenshot and the last 10 steps arrived. Missing: a Session Replay link (finding {replay}), which we now attach as a user attribute, and the steps are unreadable for SwiftUI (finding {steps}). The screenshot is a long-lived signed link, not a Jira attachment (finding {jirapublic}).` },
  '20': { prefix: 'Readable crash (HeartRateCalibration.offset',
    text: `Readable crash (HeartRateCalibration.offset, ChaosActions.swift:8, called from ChaosView.body) and app hang (ChaosActions.freeze, over 3 s). One SwiftUI view is masked with .luciq_privateView(). Repro steps and user steps don't name our SwiftUI screens or taps, even with LuciqTracedView (findings {steps} and {traced}).` },
};

function cleanupFindings() {
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
    if (row.getNumCells() < 3) continue;
    const description = text(row.getCell(2));
    const reword = REWORDS.find(r => description.indexOf(r.prefix) === 0);
    if (!reword) continue;
    row.getCell(1).setText(reword.type);
    row.getCell(2).setText(reword.text);
    log.push('reworded #' + text(row.getCell(0)) + ': ' + reword.text.slice(0, 60));
  }

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
