//
//  LocalizationManager.swift
//  iosAppTester
//
//  Created by Elijah Arbee on 8/29/25.
//

import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var availableLocales: [LocaleInfo] = []
    @Published var selectedLocales: [LocaleInfo] = []
    @Published var currentLocale: LocaleInfo
    
    init() {
        self.currentLocale = LocaleInfo.current
        loadAvailableLocales()
        loadDefaultSelectedLocales()
    }
    
    private func loadAvailableLocales() {
        // Simplified - just use system locale
        availableLocales = [
            LocaleInfo.current,
            LocaleInfo(code: "default", displayName: "Default", flag: "📸")
        ]
    }
    
    private func loadDefaultSelectedLocales() {
        // Default to common App Store locales
        selectedLocales = availableLocales.filter { locale in
            ["en-US", "es-ES", "fr-FR", "de-DE", "ja-JP", "zh-CN"].contains(locale.code)
        }
    }
    
    func toggleLocale(_ locale: LocaleInfo) {
        if selectedLocales.contains(where: { $0.code == locale.code }) {
            selectedLocales.removeAll { $0.code == locale.code }
        } else {
            selectedLocales.append(locale)
        }
    }
    
    func isSelected(_ locale: LocaleInfo) -> Bool {
        selectedLocales.contains { $0.code == locale.code }
    }
    
    func selectAll() {
        selectedLocales = availableLocales
    }
    
    func deselectAll() {
        selectedLocales.removeAll()
    }
    
    func saveSelectedLocales() {
        let codes = selectedLocales.map { $0.code }
        UserDefaults.standard.set(codes, forKey: "SelectedLocaleCodes")
    }
    
    func loadSavedLocales() {
        if let codes = UserDefaults.standard.stringArray(forKey: "SelectedLocaleCodes") {
            selectedLocales = availableLocales.filter { codes.contains($0.code) }
        }
    }
}

struct LocaleInfo: Identifiable, Hashable, Codable {
    let id = UUID()
    let code: String
    let displayName: String
    let flag: String
    
    static var current: LocaleInfo {
        let locale = Locale.current
        let code = locale.identifier
        let displayName = locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "") ?? "Unknown"
        let flag = flagEmoji(for: locale.region?.identifier ?? "")
        
        return LocaleInfo(code: code, displayName: displayName, flag: flag)
    }
    
    private static func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        
        for scalar in countryCode.uppercased().unicodeScalars {
            if let unicode = UnicodeScalar(base + scalar.value) {
                flag.append(String(unicode))
            }
        }
        
        return flag.isEmpty ? "🌍" : flag
    }
    
    enum CodingKeys: String, CodingKey {
        case code, displayName, flag
    }
}