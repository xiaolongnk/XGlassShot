//
//  LocalizationManager.swift
//  screenKit
//
//  Handles internationalization and language switching
//

import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"
    case japanese = "ja"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case korean = "ko"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "简体中文"
        case .japanese: return "日本語"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .korean: return "한국어"
        }
    }
    
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        case .japanese: return "日本語"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .korean: return "한국어"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .chinese: return "🇨🇳"
        case .japanese: return "🇯🇵"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .korean: return "🇰🇷"
        }
    }
}

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            loadLocalizedStrings()
            languageVersion += 1
        }
    }
    
    // Published property to trigger view updates when language changes
    @Published var languageVersion: Int = 0
    
    private var localizedStrings: [String: String] = [:]
    private let bundle: Bundle
    
    private init() {
        // Load saved language or default to system language
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            // Try to match system language
            let systemLang = Locale.preferredLanguages.first ?? "en"
            if systemLang.hasPrefix("zh") {
                currentLanguage = .chinese
            } else if systemLang.hasPrefix("ja") {
                currentLanguage = .japanese
            } else if systemLang.hasPrefix("es") {
                currentLanguage = .spanish
            } else if systemLang.hasPrefix("fr") {
                currentLanguage = .french
            } else if systemLang.hasPrefix("de") {
                currentLanguage = .german
            } else if systemLang.hasPrefix("ko") {
                currentLanguage = .korean
            } else {
                currentLanguage = .english
            }
        }
        
        bundle = Bundle.main
        loadLocalizedStrings()
    }
    
    private func loadLocalizedStrings() {
        guard let url = bundle.url(forResource: "Localizable", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: String]],
              let langDict = json[currentLanguage.rawValue] else {
            // Fallback to English if localization file not found
            if currentLanguage != .english {
                loadEnglishFallback()
            }
            return
        }
        localizedStrings = langDict
    }
    
    private func loadEnglishFallback() {
        // Load English as fallback
        guard let url = bundle.url(forResource: "Localizable", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: String]],
              let langDict = json["en"] else {
            return
        }
        localizedStrings = langDict
    }
    
    func localized(_ key: String, fallback: String? = nil) -> String {
        if let localized = localizedStrings[key], !localized.isEmpty {
            return localized
        }
        return fallback ?? key
    }
}

// MARK: - Convenience Extension

extension String {
    var localized: String {
        // Access languageVersion to trigger observation updates
        _ = LocalizationManager.shared.languageVersion
        return LocalizationManager.shared.localized(self, fallback: self)
    }
}
