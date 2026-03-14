import Foundation
import FirebaseCore
import FirebaseAuth

struct AccessAlert: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}

enum FirebaseAccessError: LocalizedError {
    case accessDenied(message: String, title: String)
    case invalidResponse
    case unauthenticated

    var errorDescription: String? {
        switch self {
        case let .accessDenied(message, _):
            return message
        case .invalidResponse:
            return "The server returned an invalid response."
        case .unauthenticated:
            return "You must be signed in to continue."
        }
    }

    var title: String {
        switch self {
        case let .accessDenied(_, title):
            return title
        case .invalidResponse:
            return "Request Failed"
        case .unauthenticated:
            return "Authentication Required"
        }
    }
}

private struct GateFailure: Decodable {
    let success: Bool
    let code: String
    let message: String
    let resetAt: Int?
    let resetText: String?
}

private struct GateQuota: Decodable {
    let used: Int
    let remaining: Int?
    let limit: Int?
    let period: String?
    let resetAt: Int?
    let resetText: String?
}

private struct GateEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let quota: GateQuota?
    let code: String?
    let message: String?
    let resetAt: Int?
    let resetText: String?
}

private struct CallableWrapper<T: Decodable>: Decodable {
    let result: T?
    let error: CallableErrorPayload?
}

private struct CallableErrorPayload: Decodable {
    let status: String?
    let message: String?
}

private struct FeatureFlagsResponse: Decodable {
    let addLocalMusicButton: Bool?
    let emailLogin: Bool?
    let soundcloudLogin: Bool?
    let soundcloudSongs: Bool?
}

private struct StorageURLResponse: Decodable {
    let url: String
}

@MainActor
final class FirebaseAPI: ObservableObject {
    static let shared = FirebaseAPI()

    @Published var addLocalMusicEnabled = false
    @Published var emailLoginEnabled = true
    @Published var soundcloudLoginEnabled = false
    @Published var accessAlert: AccessAlert?

    private let functionsRegion = "europe-west1"

    private init() {
        FirebaseApp.configure()
    }

    func fetchFeatureFlags() async {
        do {
            let dict: FeatureFlagsResponse = try await gateData(action: "featureFlags")
            addLocalMusicEnabled = dict.addLocalMusicButton ?? false
            emailLoginEnabled = dict.emailLogin ?? true
            soundcloudLoginEnabled = dict.soundcloudLogin ?? dict.soundcloudSongs ?? false
        } catch {
            if let accessError = error as? FirebaseAccessError {
                presentAccessAlert(for: accessError)
            }
            print("Failed to fetch feature flags: \(error)")
        }
    }

    func fetchSoundcloudSongs() async throws -> [Song] {
        try await gateData(action: "soundcloudSongs")
    }

    func fetchFirebaseSongs(accessIdentifier: String) async throws -> [Song] {
        try await gateData(action: "firebaseSongs", extraPayload: [
            "accessIdentifier": normalizeAccessIdentifier(accessIdentifier)
        ])
    }

    func fetchStorageDownloadURL(path: String) async throws -> URL {
        let response: StorageURLResponse = try await gateData(action: "storageURL", extraPayload: [
            "songId": path,
            "accessIdentifier": storedAccessIdentifier()
        ])
        guard let url = URL(string: response.url) else {
            throw FirebaseAccessError.invalidResponse
        }
        return url
    }

    func presentAccessAlert(for error: FirebaseAccessError) {
        accessAlert = AccessAlert(title: error.title, message: error.localizedDescription)
    }

    func clearAccessAlert() {
        accessAlert = nil
    }

    private func gateData<T: Decodable>(action: String, extraPayload: [String: Any] = [:]) async throws -> T {
        let envelope: GateEnvelope<T> = try await callGate(action: action, extraPayload: extraPayload)
        if envelope.success, let data = envelope.data {
            return data
        }

        let title = titleForFailure(code: envelope.code, period: envelope.quota?.period)
        let message = denialMessage(message: envelope.message, resetText: envelope.resetText)
        throw FirebaseAccessError.accessDenied(message: message, title: title)
    }

    private func callGate<T: Decodable>(action: String, extraPayload: [String: Any]) async throws -> T {
        try await FirebaseAuthGate.shared.ensureSignedIn()

        guard let user = Auth.auth().currentUser else {
            throw FirebaseAccessError.unauthenticated
        }

        let token = try await user.getIDToken()
        guard let projectId = FirebaseApp.app()?.options.projectID else {
            throw FirebaseAccessError.invalidResponse
        }

        let functionURL = URL(string: "https://\(functionsRegion)-\(projectId).cloudfunctions.net/nightingaleAccess")!
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var payload = extraPayload
        payload["action"] = action
        request.httpBody = try JSONSerialization.data(withJSONObject: ["data": payload], options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw FirebaseAccessError.invalidResponse
        }

        let decoder = JSONDecoder()
        let wrapper = try decoder.decode(CallableWrapper<T>.self, from: data)
        if let result = wrapper.result {
            return result
        }
        if let message = wrapper.error?.message {
            throw FirebaseAccessError.accessDenied(message: message, title: "Access Denied")
        }
        throw FirebaseAccessError.invalidResponse
    }

    private func titleForFailure(code: String?, period: String?) -> String {
        switch code {
        case "blocked":
            return "Access Blocked"
        case "firebase_access_denied":
            return "Firebase Access Required"
        case "daily_quota_reached":
            return "Daily Quota Reached"
        case "weekly_quota_reached":
            return "Weekly Quota Reached"
        case "monthly_quota_reached":
            return "Monthly Quota Reached"
        default:
            if period == "day" { return "Daily Quota Reached" }
            if period == "week" { return "Weekly Quota Reached" }
            if period == "month" { return "Monthly Quota Reached" }
            return "Access Denied"
        }
    }

    private func denialMessage(message: String?, resetText: String?) -> String {
        guard let message else { return "Access denied." }
        guard let resetText, !message.lowercased().contains(resetText.lowercased()) else { return message }
        return "\(message) Access resets \(resetText)."
    }

    private func normalizeAccessIdentifier(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func storedAccessIdentifier() -> String {
        normalizeAccessIdentifier(UserDefaults.standard.string(forKey: "userEmail") ?? "")
    }
}
