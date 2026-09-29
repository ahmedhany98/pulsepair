const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';
const PR_URL = 'https://github.com/Instabug/mcp/pull/155';

function linkMcpPr() {
  const doc = DocumentApp.openById(DOC_ID);
  const tables = doc.getBody().getTables();
  const findings = tables.find(t => headerRow(t, 'Type') >= 0);
  for (let i = headerRow(findings, 'Type') + 1; i < findings.getNumRows(); i++) {
    const row = findings.getRow(i);
    if (row.getNumCells() < 3) continue;
    const cell = row.getCell(2);
    if (text(cell).indexOf('The Luciq MCP returns no dashboard link') !== 0) continue;
    if (cell.getText().indexOf('mcp/pull/155') >= 0) {
      Logger.log('already linked on #' + text(row.getCell(0)));
    } else {
      cell.appendParagraph('Fix: ' + PR_URL + ' (crash_details and bug_details now return a dashboard_url)')
        .editAsText().setLinkUrl(5, 5 + PR_URL.length - 1, PR_URL);
      Logger.log('PR linked on finding #' + text(row.getCell(0)));
    }
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
