//
//  LocalesView.swift
//  iosAppTester
//
//  Created by Elijah Arbee on 8/29/25.
//

import SwiftUI

struct LocalesView: View {
    @ObservedObject var localizationManager: LocalizationManager
    @State private var searchText = ""
    
    var filteredLocales: [LocaleInfo] {
        if searchText.isEmpty {
            return localizationManager.availableLocales
        } else {
            return localizationManager.availableLocales.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.code.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Selected Count Header
                HStack {
                    Text("\(localizationManager.selectedLocales.count) of \(localizationManager.availableLocales.count) selected")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Select All") {
                        localizationManager.selectAll()
                    }
                    
                    Button("Clear All") {
                        localizationManager.deselectAll()
                    }
                    .foregroundColor(.red)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                
                // Locales List
                List {
                    ForEach(filteredLocales) { locale in
                        LocaleRowView(
                            locale: locale,
                            isSelected: localizationManager.isSelected(locale),
                            onToggle: { localizationManager.toggleLocale(locale) }
                        )
                    }
                }
                .searchable(text: $searchText, prompt: "Search languages")
                
                // Selected Locales Preview
                if !localizationManager.selectedLocales.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Selected Languages")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(localizationManager.selectedLocales) { locale in
                                    LocaleChip(locale: locale) {
                                        localizationManager.toggleLocale(locale)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color.blue.opacity(0.05))
                }
            }
            .navigationTitle("Languages & Regions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Save Preferences") {
                        localizationManager.saveSelectedLocales()
                    }
                }
            }
        }
    }
}

struct LocaleRowView: View {
    let locale: LocaleInfo
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(locale.flag)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(locale.displayName)
                        .font(.headline)
                    Text(locale.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .imageScale(.large)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct LocaleChip: View {
    let locale: LocaleInfo
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(locale.flag)
            Text(locale.code)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .imageScale(.small)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}