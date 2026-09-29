const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';

const EPICS = [
  { match: 'We want to filter the network log to only our app', key: 'TEST-26163' },
  { match: 'The Luciq MCP returns no dashboard link', key: 'TEST-26164' },
];

function linkEpics() {
  const doc = DocumentApp.openById(DOC_ID);
  const findings = doc.getBody().getTables().find(t => headerRow(t, 'Type') >= 0);
  for (let i = headerRow(findings, 'Type') + 1; i < findings.getNumRows(); i++) {
    const row = findings.getRow(i);
    if (row.getNumCells() < 3) continue;
    const cell = row.getCell(2);
    const epic = EPICS.find(e => text(cell).indexOf(e.match) === 0);
    if (!epic || cell.getText().indexOf(epic.key) >= 0) continue;
    const url = 'https://instabug.atlassian.net/browse/' + epic.key;
    cell.appendParagraph('Epic link: ' + url).editAsText().setLinkUrl(11, 11 + url.length - 1, url);
    Logger.log('epic ' + epic.key + ' linked on finding #' + text(row.getCell(0)));
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
