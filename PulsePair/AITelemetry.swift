import Foundation
import LuciqSDK

/// What PulsePair reports to Luciq about the Ask AI feature.
///
/// M14 asks five questions about a non-deterministic feature: how slow it is,
/// how often it fails, what an answer costs, which answers users called wrong,
/// and when someone should be woken up. Luciq has no AI primitives, so each
/// question is mapped onto the nearest general primitive the SDK does have.
/// Where that mapping is a workaround rather than a fit, the comment says so
/// and the gap is logged in AI_MONITORING.md.
enum AITelemetry {
    static let flowName = "ask_ai"
    static let ratingFlowName = "ask_ai_rating"

    // MARK: - Outcome

    /// Why an Ask AI call ended. HTTP status alone can't answer this: a refusal
    /// and a truncated answer are both HTTP 200, and neither is a usable answer.
    enum Outcome: String {
        case ok
        case truncated
        case refused
        case empty
        case httpClient = "http_4xx"
        case httpServer = "http_5xx"
        case timeout
        case offline
        case transport = "transport_error"
        case decodeError = "decode_error"
    }

    struct Usage {
        var inputTokens = 0
        var outputTokens = 0
        var cacheReadTokens = 0
        var cacheCreationTokens = 0

        var billedTokens: Int { inputTokens + outputTokens }
    }

    /// One completed Ask AI call, kept in memory so a later 👎 can be reported
    /// with the same dimensions as the call it is about.
    struct Run {
        let outcome: Outcome
        let model: String
        let usage: Usage
        let costUSD: Double
        let latency: TimeInterval
        let finishedAt: Date
    }

    // MARK: - Pricing

    /// USD per million tokens, input and output.
    ///
    /// The request asks for the model in AIConfig.plist, but it also sends
    /// `fallbacks: "default"`, so a refused request can be answered by a
    /// different model. Price on the model that actually answered, not the one
    /// we asked for.
    private static let pricePerMTok: [String: (input: Double, output: Double)] = [
        "claude-opus-5": (5, 25),
        "claude-opus-4-8": (5, 25),
        "claude-opus-4-7": (5, 25),
        "claude-sonnet-5": (2, 10),
        "claude-haiku-4-5": (1, 5),
        "claude-fable-5-1": (10, 50),
        "claude-fable-5": (10, 50),
    ]

    static func cost(of usage: Usage, model: String) -> Double? {
        // Model ids sometimes carry a suffix; match on the longest known prefix.
        guard let price = pricePerMTok
            .filter({ model.hasPrefix($0.key) })
            .max(by: { $0.key.count < $1.key.count })?
            .value
        else { return nil }
        return Double(usage.inputTokens) / 1_000_000 * price.input
            + Double(usage.outputTokens) / 1_000_000 * price.output
    }

    // MARK: - Flow

    static func startFlow() {
        APM.startFlow(withName: flowName)
    }

    /// Ends the `ask_ai` flow and attaches everything Luciq can be made to hold.
    ///
    /// A flow instance takes at most 5 custom attributes and 20 unique keys
    /// across all instances, and every value is a string, so numbers have to be
    /// bucketed before they go in.
    @discardableResult
    static func endFlow(
        outcome: Outcome,
        model: String,
        usage: Usage,
        latency: TimeInterval,
        refusalCategory: String? = nil
    ) -> Run {
        let costUSD = cost(of: usage, model: model)

        setAttribute("outcome", outcome.rawValue)
        setAttribute("model_served", model)
        setAttribute("in_tokens", bucketTokens(usage.inputTokens))
        setAttribute("out_tokens", bucketTokens(usage.outputTokens))
        setAttribute("cost_usd", bucketCost(costUSD))

        APM.endFlow(withName: flowName)

        recordTokenSpans(usage)
        log(outcome: outcome, model: model, usage: usage, costUSD: costUSD,
            latency: latency, refusalCategory: refusalCategory)
        bumpTotals(usage: usage, costUSD: costUSD, failed: outcome != .ok)

        return Run(outcome: outcome, model: model, usage: usage,
                   costUSD: costUSD ?? 0, latency: latency, finishedAt: Date())
    }

    private static func setAttribute(_ key: String, _ value: String) {
        // Empty values are dropped by the SDK, and values are capped at 60 chars.
        guard !value.isEmpty else { return }
        APM.setAttributeForFlowWithName(flowName, key: key, value: String(value.prefix(60)))
    }

    // MARK: - Tokens as spans

    /// Luciq aggregates exactly one kind of number: elapsed time. There is no
    /// custom counter, gauge or sum anywhere in the SDK, so the only way to get
    /// a P50/P95 of tokens out of the dashboard is to express tokens as the
    /// duration of a custom span — 1 token becomes 1 millisecond.
    ///
    /// This is a deliberate abuse of the span API to prove the gap, not a
    /// pattern to copy. It is finding BN-1 in AI_MONITORING.md.
    private static func recordTokenSpans(_ usage: Usage) {
        guard usage.billedTokens > 0 else { return }
        let start = Date()
        // The docs give this as addCompletedCustomSpan(name:startDate:endDate:).
        // The SDK wants withName:start:end:. That is finding BN-12.
        APM.addCompletedCustomSpan(
            withName: "ai_output_tokens_as_ms",
            start: start,
            end: start.addingTimeInterval(Double(usage.outputTokens) / 1000)
        )
        APM.addCompletedCustomSpan(
            withName: "ai_input_tokens_as_ms",
            start: start,
            end: start.addingTimeInterval(Double(usage.inputTokens) / 1000)
        )
    }

    // MARK: - Logs

    /// The per-call record, for reading one session in the dashboard.
    ///
    /// The question and the answer never leave the device. PulsePair is a
    /// clinical app and a question can carry patient detail, so only a length
    /// and the shape of the call are logged.
    private static func log(
        outcome: Outcome,
        model: String,
        usage: Usage,
        costUSD: Double?,
        latency: TimeInterval,
        refusalCategory: String?
    ) {
        var line = "ask_ai outcome=\(outcome.rawValue) model=\(model)"
            + " latency_ms=\(Int(latency * 1000))"
            + " in_tokens=\(usage.inputTokens) out_tokens=\(usage.outputTokens)"
        if let costUSD { line += String(format: " cost_usd=%.5f", costUSD) }
        if usage.cacheReadTokens > 0 || usage.cacheCreationTokens > 0 {
            line += " cache_read=\(usage.cacheReadTokens) cache_write=\(usage.cacheCreationTokens)"
        }
        if let refusalCategory { line += " refusal_category=\(refusalCategory)" }

        outcome == .ok ? LCQLog.logInfo(line) : LCQLog.logError(line)

        // Kept deliberately, and not to be trusted: user event parameters merge
        // first-wins per event name, so after the first Ask AI call these values
        // are frozen and every later call's numbers are dropped. The log line
        // above is the per-call record. This is finding BN-8.
        Luciq.logUserEvent(withName: "ask_ai", parameters: [
            UserEventParam(key: "outcome", value: outcome.rawValue),
            UserEventParam(key: "model", value: model),
            UserEventParam(key: "latency_ms", value: String(Int(latency * 1000))),
            UserEventParam(key: "out_tokens", value: String(usage.outputTokens)),
        ])
    }

    // MARK: - Running totals

    /// User attributes are the only place a running total survives the session,
    /// and they are strings scoped to a user, not a metric. Good enough to
    /// answer "which clinician is burning the budget", useless for a total.
    private static func bumpTotals(usage: Usage, costUSD: Double?, failed: Bool) {
        let defaults = UserDefaults.standard
        let calls = defaults.integer(forKey: "ai_calls") + 1
        let tokens = defaults.integer(forKey: "ai_tokens") + usage.billedTokens
        let cost = defaults.double(forKey: "ai_cost") + (costUSD ?? 0)
        let failures = defaults.integer(forKey: "ai_failures") + (failed ? 1 : 0)
        defaults.set(calls, forKey: "ai_calls")
        defaults.set(tokens, forKey: "ai_tokens")
        defaults.set(cost, forKey: "ai_cost")
        defaults.set(failures, forKey: "ai_failures")

        Luciq.setUserAttribute(String(calls), withKey: "ai_calls")
        Luciq.setUserAttribute(String(tokens), withKey: "ai_tokens")
        Luciq.setUserAttribute(String(format: "%.4f", cost), withKey: "ai_cost_usd")
        Luciq.setUserAttribute(String(failures), withKey: "ai_failures")
    }

    // MARK: - Ratings

    /// A user calling an answer wrong is the only signal that separates a
    /// working AI feature from a broken one, and Luciq has nowhere to put it.
    ///
    /// Three channels are used at once, because no single one works in both
    /// builds: a zero-length flow so the rating is countable and breaks down by
    /// the same dimensions as the call, a non-fatal so it survives in
    /// Production (where bug reporting is off), and a log line for the session.
    static func rate(_ run: Run, wrong: Bool, questionLength: Int) {
        let rating = wrong ? "wrong" : "good"

        APM.startFlow(withName: ratingFlowName)
        APM.setAttributeForFlowWithName(ratingFlowName, key: "rating", value: rating)
        APM.setAttributeForFlowWithName(ratingFlowName, key: "outcome", value: run.outcome.rawValue)
        APM.setAttributeForFlowWithName(ratingFlowName, key: "model_served", value: String(run.model.prefix(60)))
        APM.setAttributeForFlowWithName(ratingFlowName, key: "out_tokens", value: bucketTokens(run.usage.outputTokens))
        APM.setAttributeForFlowWithName(
            ratingFlowName,
            key: "seconds_to_rate",
            value: bucketSeconds(Date().timeIntervalSince(run.finishedAt))
        )
        APM.endFlow(withName: ratingFlowName)

        let line = "ask_ai_rating rating=\(rating) model=\(run.model)"
            + " out_tokens=\(run.usage.outputTokens)"
            + " latency_ms=\(Int(run.latency * 1000))"
            + " question_chars=\(questionLength)"
        wrong ? LCQLog.logError(line) : LCQLog.logInfo(line)

        Luciq.logUserEvent(withName: "ask_ai_rating", parameters: [
            UserEventParam(key: "rating", value: rating),
            UserEventParam(key: "model", value: run.model),
        ])

        guard wrong else { return }
        let defaults = UserDefaults.standard
        let flags = defaults.integer(forKey: "ai_flags") + 1
        defaults.set(flags, forKey: "ai_flags")
        Luciq.setUserAttribute(String(flags), withKey: "ai_flags")

        // Non-fatals are the one report type Production still sends, so a
        // flagged answer is filed as one. It groups by model and token bucket,
        // which is the closest thing to "show me the answers users rejected".
        LuciqSetup.reportNonFatal(NSError(
            domain: "AskAI",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Answer flagged wrong (model \(run.model), \(bucketTokens(run.usage.outputTokens)) output tokens)",
            ]
        ))
    }

    // MARK: - Buckets

    /// Flow attributes are strings and the docs warn that high-cardinality
    /// values slow the dashboard down, so every number becomes a bucket and
    /// every distribution loses its tail.
    static func bucketTokens(_ tokens: Int) -> String {
        switch tokens {
        case ..<1: return "0"
        case ..<101: return "1_100"
        case ..<501: return "101_500"
        case ..<2001: return "501_2000"
        default: return "2000_plus"
        }
    }

    static func bucketCost(_ cost: Double?) -> String {
        guard let cost else { return "unknown" }
        switch cost {
        case ..<0.001: return "lt_0.001"
        case ..<0.01: return "0.001_0.01"
        case ..<0.05: return "0.01_0.05"
        case ..<0.25: return "0.05_0.25"
        default: return "gt_0.25"
        }
    }

    static func bucketSeconds(_ seconds: TimeInterval) -> String {
        switch seconds {
        case ..<5: return "lt_5s"
        case ..<30: return "5_30s"
        case ..<120: return "30_120s"
        default: return "gt_120s"
        }
    }
}
