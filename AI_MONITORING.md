# M14 · Monitoring AI features

**Mission question:** What does monitoring look like for the non-deterministic AI features in our app?

**Done when** the Ask AI screen calls a real LLM and we can answer five questions: how slow is it (P95), how often does it fail, how many tokens does an answer cost, which answers did users flag as wrong, and when should someone be alerted. Luciq has nothing built for this, so every question it can't answer is logged as a Build Next idea.

**Scope note.** Ask AI already called `api.anthropic.com/v1/messages` before this mission started, and nothing about it was measured. It didn't even appear in the Network list, because nobody had opened the screen since the key was added. Everything below is what it took to make one non-deterministic feature legible to an APM tool built for deterministic ones.

## The mapping

Luciq has no AI primitives. Each of the five questions is answered with the nearest general primitive that exists, and the column on the right is what that costs us.

| Question | Primitive used | What we lose |
| --- | --- | --- |
| How slow is it? | Network P50/P95 on the `api.anthropic.com/v1/messages` pattern, plus the `ask_ai` Flow's time to completion | Nothing, once the Apdex target is raised off 0.5 sec. The Flow number is the honest one: it's what the clinician waits for |
| How often does it fail? | `outcome` attribute on the `ask_ai` Flow, read from the Flow's Patterns breakdown | Luciq's own "Network failures" says 0% while refusals and truncated answers are going out. Failure rate has to be divided by hand from the pattern counts |
| What does an answer cost? | `in_tokens` / `out_tokens` / `cost_usd` buckets as Flow attributes, plus token counts smuggled through custom-span durations | Every number becomes a bucket. There is no sum, no average, no total spend anywhere in the product |
| Which answers were flagged wrong? | 👎 in the app → a zero-length `ask_ai_rating` Flow, a non-fatal, and a log line | No link back to the call that produced the answer, except the timestamp and the session |
| When should someone be alerted? | Flow alert on `ask_ai` P95 and drop-off; network alert on the endpoint's failure rate and Apdex | Can't alert on refusal rate, flag rate, or spend — alert conditions can't see custom attributes |

## What we changed in the app

- **`PulsePair/AITelemetry.swift`** (new) — all Luciq reporting for Ask AI: the `ask_ai` Flow and its five attributes, the token spans, the log lines, the running per-user totals, and the rating path.
- **`PulsePair/AIClient.swift`** — decodes `usage`, `model` and `stop_reason` from the response, and classifies every ending into one `Outcome`: `ok`, `truncated`, `refused`, `empty`, `http_4xx`, `http_5xx`, `timeout`, `offline`, `transport_error`, `decode_error`.
- **`PulsePair/AskAIView.swift`** — wraps the call in the Flow, adds 👍/👎 on the answer, and shows outcome, model, latency, tokens and cost under it. That panel exists because most of it can't be read back off the dashboard.

- **`PulsePair.xcodeproj`** — one build fix, unrelated to the mission but blocking it: the dSYM phase read the app token with `PlistBuddy ... 2>/dev/null`, and PlistBuddy prints `File Doesn't Exist, Will Create:` to *stdout*, not stderr. On a fresh clone the token came back non-empty, the skip never fired, the upload ran with that string as the token and returned 422, and the whole build failed. The phase now checks the file exists first.

Neither the question nor the answer leaves the device. PulsePair is a clinical app, a question can carry patient detail, and Luciq's masking handlers only cover network requests and responses — they don't touch Flow attributes or logs. Only lengths, buckets and outcomes are reported.

## Order of operations for the measurement run

The Apdex threshold change warns that it "doesn't affect your data that has been already grouped". Set it **before** generating traffic or the first batch is scored against 0.5 sec.

1. Dashboard → Network → create URL pattern `api.anthropic.com/v1/messages`, set its threshold to 8 sec, star it as a key metric.
2. Build and run the Test build. Sign in as a unique clinician.
3. Ask ~30 questions across four shapes: short factual, long-answer (to move the token buckets), one forced 400 (bad model id), one forced 401 (bad key), one airplane-mode call, one refusal-bait, and one with `max_tokens` low enough to truncate.
4. Flag 3 answers wrong and 3 correct.
5. Background and reopen the app so the session and replay sync.
6. Repeat on the Production build to prove what survives with bug reporting and network logging off.
7. Read Flows → `ask_ai` → Patterns, and Network → the new pattern. Screenshot both into `evidence/`.

## Build Next

Findings are Luciq's, not the app's. Type follows the P8 playbook's vocabulary.

| # | Type | Finding | Verified |
| --- | --- | --- | --- |
| BN-1 | Feature request | Time is the only number Luciq aggregates. There is no counter, gauge or sum, so a token count or a dollar cost can only reach the dashboard as a bucketed string — or, as we did, encoded as the duration of a custom span, where 1 token becomes 1 ms. A P95 of tokens should not require lying about milliseconds. | Dashboard + SDK |
| BN-2 | Feature request | Alert conditions for Flows are App version, Flow name, Key metric and Count. Custom flow attributes can't be used, so the three alerts an AI feature actually needs — refusal rate, flagged-answer rate, spend — can't be written at all. | Dashboard |
| BN-3 | Feature request | A refusal and a truncated answer are both HTTP 200, so Luciq's Network failure rate counts them as successes. In our run the two metrics agreed at 33.3% only because every failure happened to be an HTTP error or a client timeout. The `outcome` attribute is the only thing that would catch a refusal. | Reasoned from the API contract and `AIClient`, not produced in this run |
| BN-4 | Feature request | There is nowhere to put "the user said this answer was wrong". We had to model it as a zero-length Flow plus a non-fatal, because non-fatals are the only report type our Production build still sends. | Dashboard |
| BN-5 | Painful | Flow alerts apply only to flows exceeding 100 occurrences unless a Count condition is added. A new AI feature, which is exactly when you want to be watching, is below that floor. | Dashboard |
| BN-6 | Confusing UX | The per-URL Apdex threshold is editable, but the default 0.5 sec makes every LLM call frustrating, and the change only applies going forward. Get the order wrong and the feature's first days are scored against a target no LLM can meet — and those sessions are already counted in Frustration-Free Sessions. | Dashboard |
| BN-7 | Feature request | With server-side fallbacks on, the model that answers isn't always the model we asked for. Luciq has no dimension for "which model served this", so it has to burn one of the five flow attributes. | SDK + API |
| BN-8 | Painful | User event parameters merge first-wins per event name, so a per-call event keeps the first call's values and silently drops the rest. Unusable for per-call telemetry, and the docs don't say what the merge is scoped to. | Docs |
| BN-9 | Painful | Our Production build turns network logging off for privacy, which is also where `usage` lives. The token counts are in a response body Luciq is not allowed to read, so the app has to parse and re-report them itself. | Repo + docs |
| BN-10 | Feature request | Nothing in Luciq is prompt-aware. Masking handlers cover network requests and responses; flow attributes, logs and user events are unmasked, so any team that wants prompt text for debugging has to build its own redaction first. | SDK |
| BN-13 | Feature request | A call the client abandons is billed but uncountable. `usage` only arrives with the response, so our 120-second timeout recorded `cost_usd $0.00000` while Anthropic still charged for every token it had generated. Any cost view built from response bodies under-reports exactly the calls that went wrong. | Measured |
| BN-14 | Painful | Nothing is live. APM and session data ship on background/foreground, not continuously, so a failing AI feature stays invisible until the clinician happens to background the app. That delay sits underneath every alert threshold you might set. | Measured |
| BN-15 | Feature request | A slow generation and a broken endpoint are the same event to the SDK. Our 1500-word answer was still being generated server-side when the client gave up at 120 seconds; Luciq records a client-side network failure either way, with nothing to separate "too slow" from "broken". | Measured |
| BN-12 | Doc gap | The custom-spans page documents `APM.addCompletedCustomSpan(name:startDate:endDate:)`. The SDK exports `addCompletedCustomSpan(withName:start:end:)`. The documented call does not compile on 19.11.0. | Compiler |
| BN-11 | Feature request | No time-to-first-token. A streaming AI feature is judged by when text starts, and Luciq's network metric only knows when the response finished. | SDK |

## Results

Measured 29 Sep 2026, 15:01–15:15 EEST, Test build v1.2.0 (3), iPhone 17 simulator, one clinician (`emilys`). Nine `ask_ai` occurrences reached the dashboard: six successful, two HTTP 404 (injected by pointing `model` at a non-existent id), one client timeout.

### 1. How slow is it? P95

| Source | P50 | P95 | n |
| --- | --- | --- | --- |
| Flow `ask_ai`, all outcomes | 10 sec | **120.13 sec** | 9 |
| Flow `ask_ai`, `outcome = Ok` only | 10 sec | **14.86 sec** | 6 |
| Network `POST api.anthropic.com/v1/messages` | 9.97 sec | 14.836 sec | 9 |

Two honest answers, not one. The network number is what the HTTP call costs; the flow number is what the clinician waits for, and its P95 is the 120-second client timeout, because a call that never answers is still time someone spent waiting. Quote 14.86 sec as the feature's speed and 120.13 sec as its worst case.

### 2. How often does it fail? 33.3%

`outcome` pattern breakdown on the flow:

| outcome | Count | P50 | P95 | Apdex @0.5 sec |
| --- | --- | --- | --- | --- |
| Ok | 6 | 10 sec | 14.86 sec | 0 |
| Http_4xx | 2 | 0.39 sec | 0.83 sec | 0.75 |
| Timeout | 1 | 120.13 sec | 120.13 sec | 0 |

The network pattern independently reports **33.33% failures (3 of 9)**, which agrees exactly. It agrees only because every failure in this run was an HTTP error or a client timeout — see BN-3.

Read the Apdex column again. The two 404s score **0.75** and the six real answers score **0**. On the default target, Luciq's own quality score rewards this feature for failing fast. The flow's Apdex is 0.17 and its drop-off rate is 0.0%, so Luciq's built-in health summary calls the feature 100% completed and healthy on the day a third of its calls failed.

### 3. What does an answer cost?

| out_tokens | Count | | cost_usd | Count |
| --- | --- | --- | --- | --- |
| 501_2000 | 5 | | 0.01_0.05 | 3 |
| 101_500 | 1 | | 0.001_0.01 | 1 |
| 0 | 3 | | Unknown | 3 |

`in_tokens` and `model_served` break down the same way; `model_served` is `Claude-opus-5` on all six successes and `Unknown` on the three failures.

Distributions are all the dashboard can give. For an exact figure you have to read the log line or the in-app panel: the first call was 21 in / 694 out = **$0.01745** at claude-opus-5's $5/$25 per MTok. Luciq cannot sum, average, or total any of it, and the 3 `Unknown` calls include the timeout, which Anthropic billed for and we cannot count (BN-13).

### 4. Which answers did users flag as wrong?

- Flow `ask_ai_rating`: 2 occurrences, `rating` = Good 1, Wrong 1, at 15:02:51 and 15:10:00, both 0 ms.
- Non-fatal **`AskAI` #61**: 1 occurrence, 1 user, v1.2.0 (3), titled with the model and output-token bucket. This is the channel that survives in Production, where bug reporting is off.

Both had to be built. Neither is a thing Luciq offers.

### 5. When should someone be alerted?

Expressible today, with thresholds from the numbers above:

| Alert | Trigger | Condition | Why this number |
| --- | --- | --- | --- |
| Ask AI got slow | Flow P95 greater than 30 sec within 1 hour | Flow name = `ask_ai`, Count > 10 | Good-call P95 is 14.86 sec. 30 sec is ~2× baseline and still short of the 120 sec timeout, so it fires before users start abandoning |
| Ask AI is failing | Network failure rate greater than 10% within 3 hours | Key metric only, Count > 10 | The endpoint is a key metric. 33.3% was injected; a healthy baseline is near zero, so 10% is a real signal |
| Ask AI degraded | Flow Apdex less than 0.5 within 1 day | Flow name = `ask_ai` | Only meaningful once the flow's target is raised off 0.5 sec — see below |

Not expressible, and these are the three you would actually want: **refusal rate**, **flagged-wrong rate**, and **spend per hour**. Alert conditions for Flows are limited to App version, Flow name, Key metric and Count, so no alert can read a custom attribute (BN-2). Flow alerts also apply only to flows above 100 occurrences unless a Count condition is added (BN-5), and the shipped network templates default to `Count > 1000`, which this app will never reach.

### Evidence

- `evidence/m14-call-panel.png` — the in-app panel: outcome `ok`, `claude-opus-5`, 10.20 sec, 21 in / 685 out, $0.01723. This is the per-call detail the dashboard cannot show.
- `evidence/fill-tracker.gs` — M14 mission entry and eight M14 findings, for the P8 team tracker.
- Live: the [`ask_ai` flow](https://dashboard.luciq.ai/applications/pulsepair/production/flows/da355225-2b41-4bfc-b624-d0e152455887), the [`ask_ai_rating` flow](https://dashboard.luciq.ai/applications/pulsepair/production/flows/a3da3d7e-a275-49b0-871a-b6bbfa70ea68), and the [Anthropic endpoint](https://dashboard.luciq.ai/applications/pulsepair/production/network) in Network.

### Dashboard configuration applied

- Custom URL pattern `POST api.anthropic.com/v1/messages` created, and marked a key metric.
- Its Apdex target raised from the custom-pattern default of 2 sec to **8 sec**. Apdex still reads 0.06 because the change is not retroactive — exactly BN-6.
- **Still to do:** the `ask_ai` and `ask_ai_rating` flows are both on the 0.5 sec default target, which is what produces the Apdex 0.17. Raise `ask_ai` to 15 sec before the next run.

### What this run did not produce

No refusal (`stop_reason: "refusal"`) and no `max_tokens` truncation occurred, so BN-3 remains reasoned from the API contract rather than measured. Both need a dedicated build to force. One further `ask_ai` occurrence had not synced at the time of reading, which is BN-14 in miniature.
