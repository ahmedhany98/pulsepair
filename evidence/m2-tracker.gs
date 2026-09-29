const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';
const IMAGE = 'https://raw.githubusercontent.com/ahmedhany98/pulsepair/main/evidence/m2-bug5-recording-disconnect.jpg';
const BUG5 = 'https://dashboard.luciq.ai/applications/pulsepair/production/bugs/5';
const REPLAY5 = 'https://dashboard.luciq.ai/applications/pulsepair/production/session-replay/1790680007271-653863919';

const COMMENT = `A teammate secretly broke PulsePair on an iPhone 15 and sent one vague report: bug #5, "The button is not working!". Reconstructed using only Luciq: signed in at 13:59 (login 200), left the app for 7 minutes, then on Chaos opened Heavy list (14:08:49), ran Slow call (14:08:52, 5.8 s) and Server error (14:09:56, HTTP 500); went to the Sensor tab, scanned and connected (14:11:30-34), then tapped Disconnect repeatedly. Bug #5's screen recording shows three Disconnect taps while the screen keeps saying "Connected to PulsePair HR-200". The broken button is Disconnect on the Pair sensor screen. User steps alone could not tell which button it was, because every tap is logged as a generic SwiftUI class (finding {steps}); the screen recording, the network log and the timeline gave it away.`;

function fillM2() {
  const doc = DocumentApp.openById(DOC_ID);
  const tables = doc.getBody().getTables();
  const findings = tables.find(t => headerRow(t, 'Type') >= 0);
  let steps = '?';
  for (let i = headerRow(findings, 'Type') + 1; i < findings.getNumRows(); i++) {
    const row = findings.getRow(i);
    if (row.getNumCells() > 2 && text(row.getCell(2)).indexOf('SwiftUI user steps are unreadable') === 0) steps = text(row.getCell(0));
  }
  const missions = tables.find(t => t.getText().indexOf('Regression and hotfix') >= 0);
  for (let i = 0; i < missions.getNumRows(); i++) {
    const row = missions.getRow(i);
    if (row.getNumCells() < 3 || !/^M2\b/.test(text(row.getCell(0)))) continue;
    const shot = row.getCell(1);
    if (!shot.findElement(DocumentApp.ElementType.INLINE_IMAGE)) {
      const image = shot.appendImage(UrlFetchApp.fetch(IMAGE).getBlob());
      image.setHeight(Math.round(image.getHeight() * 260 / image.getWidth())).setWidth(260);
      shot.appendParagraph('Bug #5 in Luciq').setLinkUrl(BUG5);
      shot.appendParagraph('Bug #5 session replay').setLinkUrl(REPLAY5);
    }
    if (text(row.getCell(2)) === '') row.getCell(2).setText(COMMENT.replace('{steps}', '#' + steps));
    Logger.log('M2 filled');
  }
  doc.saveAndClose();
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
