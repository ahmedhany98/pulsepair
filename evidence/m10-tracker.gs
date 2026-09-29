const DOC_ID = '1p9_ypHIIPdwN4ALYgUM-VYFovhWXdpkpWFndAlqw26g';
const IMAGE = 'https://raw.githubusercontent.com/ahmedhany98/pulsepair/main/evidence/m10-devices.png';
const APM = 'https://dashboard.luciq.ai/applications/pulsepair/production';

const COMMENT = `We compared app launch and screen loading across two device profiles: a real iPhone 15 (iOS 26.6.1) and iOS simulators (iOS 26.0, 26.2 and 27.0). Cold launch: iPhone 15 p50 290 ms, Apdex 0.67 over 9 launches; simulators p50 3.65 s, Apdex 0.23 over 26. By OS, all 14 cold launches on iOS 27.0 were frustrating (Apdex 0.00, p50 3.75 s, p95 16.9 s), against p50 1.0 s on iOS 26.2 and 290 ms on iOS 26.6.1. Pair sensor screen loading: iPhone 15 p50 110 ms and p95 110 ms, simulators p50 150 ms and p95 552 ms. Recommendation: keep supporting iPhone 15 on iOS 26.x, don't certify iOS 27.0 until its cold launch is fixed, and don't base device decisions on simulator runs, which are debug builds. Next: repeat on a genuinely low-end device, which we didn't have today.`;

function fillM10() {
  const doc = DocumentApp.openById(DOC_ID);
  const missions = doc.getBody().getTables().find(t => t.getText().indexOf('Regression and hotfix') >= 0);
  for (let i = 0; i < missions.getNumRows(); i++) {
    const row = missions.getRow(i);
    if (row.getNumCells() < 3 || !/^M10\b/.test(row.getCell(0).getText().trim())) continue;
    const shot = row.getCell(1);
    if (!shot.findElement(DocumentApp.ElementType.INLINE_IMAGE)) {
      const image = shot.appendImage(UrlFetchApp.fetch(IMAGE).getBlob());
      image.setHeight(Math.round(image.getHeight() * 300 / image.getWidth())).setWidth(300);
      shot.appendParagraph('Luciq APM for PulsePair').setLinkUrl(APM);
    }
    if (row.getCell(2).getText().trim() === '') row.getCell(2).setText(COMMENT);
    Logger.log('M10 filled');
  }
  doc.saveAndClose();
}
