# P8 · The Regulated QA Lead: team playbook

**Verdict question:** Will every bug land in our certified Jira with full context, while nothing gets recorded in production?

**We walk away if** anything records continuously in production, or anything bypasses Jira.

Everything below comes from the public docs (docs.luciq.ai) and was checked against the page it cites. Where the docs are silent or contradict themselves, that gap is a finding: screenshot the page and log it.

## The app

`PulsePair` (SwiftUI), in `~/repositories/pulsepair`.

| Command | What you get |
| --- | --- |
| `./run.sh` | Test build (yellow banner): bug reporting, replay and masking all on |
| `./run.sh Production` | Production build (red banner): crash reports and APM only |
| `VERSION=1.1.0 BUILD=2 ./run.sh` | A new version, for Core Path 14 and M1 |

- **Shake in the simulator:** Ctrl+Cmd+Z, or tap the floating button.
- **Crashes:** `run.sh` launches without the Xcode debugger. Crash, then relaunch the app so the report is sent.
- **Replays:** they sync only after the app is reopened, in batches up to every 6 hours. Background the app and reopen it early. Don't wait until 15:00.

## Missions, in order

### M4 · No personal data leaves the device (bonus +15)

Done when a replay, a bug report and a network log are captured with the email, the card number and the auth header all masked.

1. **Screenshots are already masked.** The Test build calls `Luciq.setAutoMaskScreenshots([.textInputs, .labels, .media])`. The iOS default is `maskNothing`, while Android masks everything by default. That difference is finding #1.
2. **Request masking is already on.** Headers `Authorization`, `Cookie`, `X-API-Key` and `token` are masked, and so are body keys `password`, `email`, `cardNumber`, `ssn` and `iban`.
3. **Response masking is NOT on.** The official AI setup guide only covers requests, so the patient profile response from `users/1` will likely show email, SSN and card in the clear. Screenshot that first (it's the extra-credit leak). Then add `NetworkLogger.setResponseObfuscationHandler { data, response, completion in … }`. Call `completion` on every path.
4. **Mask one SwiftUI view.** Try `.Luciq_privateView()` on the Billing section. The docs spell it three different ways, so log which one compiles.
5. **Stop real labels in the steps.** Add `Luciq.viewsContentCaptureEnabled = false` before `Luciq.start`, so User Steps and Repro Steps say "a button" instead of the real label.
6. **Collect the evidence:** a replay frame, the bug screenshot, and one network-log entry.
7. **More leaks to try for extra credit:**
   - A screen recording attachment. Auto-masking isn't applied to recordings; only private views are.
   - Name and email sent through `identifyUser`.
   - The "Device location" attribute.

### M12 · Bug reports support can act on (bonus +15), also Core Path 13

Done when a bug lands in Jira with device, steps and a replay link, without asking the user anything.

1. **Collect the required fields first.** Get the list of required fields on the sandbox Jira project from the Support Desk. Each one needs a mapping, and the Test step fails without it.
2. **Connect Jira.** Go to Settings → Integrations → Jira Cloud and choose **OAuth 2.0**. Don't use the service-account options: they can't register the webhook, so two-way sync breaks. That's a finding for a locked-down company like ours.
3. **Map and test.** Map each required field to a Luciq field of the same type, click Test, and screenshot the result.
4. **Forward with a rule, not blanket forwarding.** Leave automatic forwarding OFF. Instead, create a rule: Alerts & Rules → Create → Bugs → "Bug is reported" → condition "App version = Test build" → Forward to Jira.
5. **File a bug and audit the Jira issue.** Shake, file a one-line bug, then open the Jira issue. Check it for device, OS, app version, steps, screenshot and a replay link. Log anything missing.
   - The iOS docs describe no link from a bug report to its replay (KMP has `getSessionReplayLink()`, iOS doesn't).
   - Replays arrive up to 6 hours later.
   - Either one alone could fail this mission, so test it early.
6. **Test two-way sync.** Close the issue in Jira and comment on it, then check that the Luciq status updates.

### M2 · The bug nobody can reproduce (bonus +15)

1. **Log in as a unique tester.** Every tester must sign in with their own dummyjson user, not everyone as `emilys`. Otherwise every report looks like the same person.
2. **The saboteur walks a secret path**, for example Patient → Sessions → Save session → Chaos → Server error → Freeze. Then they shake, send a report that just says "it broke", and background and reopen the app.
3. **The investigators reconstruct it** in this order:
   - Bug details: device, OS, app version and user.
   - Repro Steps, then User Steps, then Network logs (look for the 500 and the slow call), then the Session Profiler.
   - Session Replay: search by the saboteur's email and match the time.
4. **Score it.** Write the reconstructed steps, reveal the real script, and log every step Luciq missed.

### M20 · SwiftUI depth (hard, +15)

Most of this is already done by the missions above: readable crash, 5-second app hang, masking a SwiftUI view.

- **Check the step names.** Do Repro Steps and User Steps name our SwiftUI screens and taps, or come through generic? Screen names need `LuciqTracedView(name:)`.
- **Log every place SwiftUI support falls short.**

## Production proof, for the verdict

The Production build starts Luciq with bug reporting, Session Replay, repro steps, user steps and network logs all off. It identifies the user by ID only.

1. Run `./run.sh Production` and use every screen.
2. Background and reopen the app.
3. Check the dashboard: filter by the Production build's app version, and expect crashes and APM data only.

The honest caveat: the docs say `SessionReplay.enabled = false` stops data being *sent*. They don't say it stops capture. The only fully documented "nothing in production" option is not starting the SDK at all in Release. We have to choose which of the two we'd take to our regulator.

## Findings to log now (screenshot the doc page)

| # | Type | Finding |
| --- | --- | --- |
| 1 | Painful | iOS screenshot masking defaults to `maskNothing`, while Android masks everything. A healthcare app leaks personal data in screenshots unless it opts in. |
| 2 | Doc gap | The iOS AI agent guide's "iOS Screenshot Masking" link goes to a Flutter page. |
| 3 | Doc gap | The iOS AI agent guide's `common-workflow.md` links (github.com/Instabug/luciq-docs) return 404. |
| 4 | Doc gap | The AI guide says pin SPM with `exact`, but the `luciq-setup` skill says `upToNextMajorVersion`. |
| 5 | Doc gap | The dSYM script sample uses `exit 1` while the same page says to use `exit 0`. It also hardcodes `APP_TOKEN` in the project file, even though the setup skill says never to commit tokens. |
| 6 | Painful | The SDK is a 133 MB download. Resolving the package took 30+ minutes on the office network. |
| 7 | Doc gap | The AI guide's network masking covers requests only. Personal data in response bodies is logged in the clear. Confirm this with a dashboard screenshot. |
| 8 | Confusing UX | Our app was created in production mode only. We found no documented way to add a beta mode for test builds. |
| 9 | Feature request | The crash list can't be filtered by foreground/background, only broken down inside a single crash. That's our win condition. Confirm in the dashboard. |
| 10 | Doc gap | The Jira docs contradict each other on what two-way sync needs (Marketplace add-on vs OAuth/Basic). |
| 11 | Feature request | There's no single iOS "privacy mode" switch. Making production record nothing takes 5+ separate APIs. |
| 12 | Feature request | Apple Watch companion support isn't documented. |
