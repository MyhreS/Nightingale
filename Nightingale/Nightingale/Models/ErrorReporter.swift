import Foundation
import UIKit

struct ErrorReport: Codable, Equatable {
    let message: String
    let context: String
    let source: String?
    let songId: String?
    let songName: String?
    let clientTimestamp: Double
    let appVersion: String
    let buildNumber: String
    let osVersion: String
    let deviceModel: String
    let accessIdentifier: String?
}

/// Queues app errors and uploads them to Firebase (`reportErrors`), which keeps the newest 500 for 30 days.
/// The queue is persisted so errors that happen offline are sent on a later launch.
@MainActor
final class ErrorReporter {
    static let shared = ErrorReporter()

    private let queueKey = "pendingErrorReports.v1"
    private let maxQueuedReports = 100
    private let batchSize = 20
    private let duplicateWindow: TimeInterval = 60
    private let flushDelayNanoseconds: UInt64 = 2_000_000_000

    private var lastReportedAt: [String: Date] = [:]
    private var isFlushing = false
    private var scheduledFlush: Task<Void, Never>?

    private init() {}

    func report(_ message: String, context: String, song: Song? = nil, error: Error? = nil) {
        let fullMessage = error.map { "\(message) — \(String(describing: $0))" } ?? message
        let dedupeKey = "\(context)|\(song?.songId ?? "")|\(fullMessage)"
        let now = Date()
        if let last = lastReportedAt[dedupeKey], now.timeIntervalSince(last) < duplicateWindow {
            return
        }
        lastReportedAt[dedupeKey] = now

        let info = Bundle.main.infoDictionary
        let email = UserDefaults.standard.string(forKey: "userEmail")?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let report = ErrorReport(
            message: fullMessage,
            context: context,
            source: song?.streamingSource.rawValue,
            songId: song?.songId,
            songName: song?.name,
            clientTimestamp: (now.timeIntervalSince1970 * 1000).rounded(),
            appVersion: info?["CFBundleShortVersionString"] as? String ?? "unknown",
            buildNumber: info?["CFBundleVersion"] as? String ?? "unknown",
            osVersion: UIDevice.current.systemVersion,
            deviceModel: Self.deviceModel,
            accessIdentifier: email?.isEmpty == false ? email : nil
        )

        var queue = loadQueue()
        queue.append(report)
        if queue.count > maxQueuedReports {
            queue.removeFirst(queue.count - maxQueuedReports)
        }
        saveQueue(queue)
        scheduleFlush()
    }

    func flush() {
        guard !isFlushing else { return }
        guard !loadQueue().isEmpty else { return }
        isFlushing = true

        Task { [weak self] in
            guard let self else { return }
            defer { isFlushing = false }

            while true {
                let batch = Array(loadQueue().prefix(batchSize))
                guard !batch.isEmpty else { return }
                do {
                    try await FirebaseAPI.shared.reportErrors(batch)
                } catch {
                    // Keep the queue; it is retried on the next foreground or error.
                    print("Failed to upload error reports: \(error)")
                    return
                }
                var queue = loadQueue()
                queue.removeAll { batch.contains($0) }
                saveQueue(queue)
            }
        }
    }

    private func scheduleFlush() {
        scheduledFlush?.cancel()
        scheduledFlush = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.flushDelayNanoseconds ?? 0)
            guard !Task.isCancelled else { return }
            self?.flush()
        }
    }

    private func loadQueue() -> [ErrorReport] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([ErrorReport].self, from: data) else {
            return []
        }
        return queue
    }

    private func saveQueue(_ queue: [ErrorReport]) {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        UserDefaults.standard.set(data, forKey: queueKey)
    }

    private static let deviceModel: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }()
}
