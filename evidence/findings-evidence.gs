const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';
const IMG = 'https://raw.githubusercontent.com/ahmedhany98/pulsepair/main/evidence/';

const EVIDENCE = [
  { match: 'the session replay link is missing from the bug report', img: 'f-jira-template.png', label: 'Jira TEST-26129 (no replay link)', url: 'https://instabug.atlassian.net/browse/TEST-26129' },
  { match: 'create surveys through the mcp', img: 'f-mcp-survey-tools.png' },
  { match: 'the luciq mcp returns no dashboard link', img: 'f-mcp-no-dashboard-link.png' },
];

function addFindingEvidence() {
  const doc = DocumentApp.openById(DOC_ID);
  const findings = doc.getBody().getTables().find(t => headerRow(t, 'Type') >= 0);
  for (let i = headerRow(findings, 'Type') + 1; i < findings.getNumRows(); i++) {
    const row = findings.getRow(i);
    if (row.getNumCells() < 4) continue;
    const description = text(row.getCell(2)).toLowerCase();
    const entry = EVIDENCE.find(e => description.indexOf(e.match) === 0);
    const cell = row.getCell(3);
    if (!entry || cell.findElement(DocumentApp.ElementType.INLINE_IMAGE)) continue;
    const image = cell.appendImage(UrlFetchApp.fetch(IMG + entry.img).getBlob());
    image.setHeight(Math.round(image.getHeight() * 220 / image.getWidth())).setWidth(220);
    if (entry.url) cell.appendParagraph(entry.label).setLinkUrl(entry.url);
    Logger.log('evidence added to finding #' + text(row.getCell(0)));
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
