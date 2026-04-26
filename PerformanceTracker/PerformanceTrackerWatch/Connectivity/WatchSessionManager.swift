import Foundation
import WatchConnectivity
import Observation

/// Watch side of the WatchConnectivity session. iOS has the mirror implementation.
@Observable
@MainActor
public final class WatchSessionManager: NSObject, WCSessionDelegate {
    public static let shared = WatchSessionManager()

    public var latestPayload: WatchMessage.AssessmentPayload?
    public var lastError: String?

    override private init() { super.init() }

    public func activate() {
        guard WCSession.isSupported() else {
            lastError = "WCSession not supported"
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    public func requestLatest() {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let msg = WatchMessage.requestLatestAssessment
        guard let data = try? JSONEncoder().encode(msg) else { return }
        session.sendMessageData(data, replyHandler: { [weak self] reply in
            Task { @MainActor in self?.handleReplyData(reply) }
        }, errorHandler: { [weak self] err in
            Task { @MainActor in self?.lastError = err.localizedDescription }
        })
    }

    public func sendQuickLog(_ log: WatchMessage.QuickLog) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let msg = WatchMessage.quickLog(log)
        guard let data = try? JSONEncoder().encode(msg) else { return }
        session.sendMessageData(data, replyHandler: nil, errorHandler: { [weak self] err in
            Task { @MainActor in self?.lastError = err.localizedDescription }
        })
    }

    private func handleReplyData(_ data: Data) {
        guard let decoded = try? JSONDecoder().decode(WatchMessage.self, from: data) else { return }
        if case let .assessmentPayload(payload) = decoded {
            latestPayload = payload
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated public func session(_ session: WCSession,
                                    activationDidCompleteWith state: WCSessionActivationState,
                                    error: Error?) {
        // no-op
    }

    nonisolated public func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let decoded = try? JSONDecoder().decode(WatchMessage.self, from: messageData) else { return }
        if case let .assessmentPayload(payload) = decoded {
            Task { @MainActor in self.latestPayload = payload }
        }
    }

    // iOS-only WCSessionDelegate methods. Marked unavailable on watchOS by Apple.
    #if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate so future messages reach us.
        session.activate()
    }
    #endif
}
