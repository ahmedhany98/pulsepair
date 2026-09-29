const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';

const FIXES = {
  '2': [[' \\(finding #9\\)', '']],
  '12': [['SwiftUI steps are unreadable \\(finding #9\\)', 'SwiftUI steps are unreadable']],
  '20': [[' \\(findings #9 and #10\\)', '']],
};

function fixRefs() {
  const doc = DocumentApp.openById(DOC_ID);
  const missions = doc.getBody().getTables().find(t => t.getText().indexOf('Regression and hotfix') >= 0);
  for (let i = 0; i < missions.getNumRows(); i++) {
    const row = missions.getRow(i);
    if (row.getNumCells() < 3) continue;
    const key = (row.getCell(0).getText().trim().match(/^M(\d+)\b/) || [])[1];
    if (!FIXES[key]) continue;
    FIXES[key].forEach(([pattern, replacement]) => row.getCell(2).editAsText().replaceText(pattern, replacement));
    Logger.log('M' + key + ': ' + row.getCell(2).getText().replace(/\s+/g, ' ').slice(-120));
  }
  doc.saveAndClose();
}
