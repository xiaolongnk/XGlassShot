import Foundation

enum LegacySettings {
    static func removeCloudAIKey(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: "anthropicAPIKey")
    }
}
