//
//  LanguageSwitcher.swift
//  screenKit
//
//  Fancy language switcher component with glassmorphic design
//

import SwiftUI

struct LanguageSwitcher: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isExpanded = false
    @State private var hoveredLanguage: AppLanguage?
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.cyan)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isExpanded)
                
                Text(localizationManager.currentLanguage.flag)
                    .font(.system(size: 14))
            }
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.6))
            )
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(isExpanded ? 0.3 : 0.15),
                                .white.opacity(isExpanded ? 0.15 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(alignment: .bottom) {
            if isExpanded {
                ZStack {
                    // Backdrop to catch clicks
                    Color.black.opacity(0.001)
                        .frame(width: 3000, height: 3000) // Large enough to cover screen
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                        }
                        
                    LanguageMenu(
                        currentLanguage: localizationManager.currentLanguage,
                        hoveredLanguage: $hoveredLanguage,
                        onSelect: { language in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                localizationManager.currentLanguage = language
                                isExpanded = false
                            }
                        }
                    )

                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95, anchor: .bottom).combined(with: .opacity),
                        removal: .scale(scale: 0.95, anchor: .bottom).combined(with: .opacity)
                    ))
                    .offset(y: -230) // Move significantly higher for longer list
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 5) // Slightly stronger shadow
                }
                .frame(width: 3000, height: 3000)
                .position(x: 18, y: 0)
            }
        }
        .zIndex(100)
        .onChange(of: isExpanded) { _, newValue in
            if !newValue {
                hoveredLanguage = nil
            }
        }
    }
}

struct LanguageMenu: View {
    let currentLanguage: AppLanguage
    @Binding var hoveredLanguage: AppLanguage?
    let onSelect: (AppLanguage) -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(AppLanguage.allCases) { language in
                LanguageMenuItem(
                    language: language,
                    isSelected: language == currentLanguage,
                    isHovered: hoveredLanguage == language,
                    onHover: { hoveredLanguage = $0 },
                    onSelect: { onSelect(language) }
                )
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.9))
        )
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .frame(width: 200)
    }
}

struct LanguageMenuItem: View {
    let language: AppLanguage
    let isSelected: Bool
    let isHovered: Bool
    let onHover: (AppLanguage?) -> Void
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(language.flag)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary(for: colorScheme))
                    
                    Text(language.nativeName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textSecondary(for: colorScheme))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.cyan)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.cyan.opacity(0.15) : (isHovered ? Color.primary.opacity(0.08) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected ? Color.cyan.opacity(0.4) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            onHover(hovering ? language : nil)
        }
    }
}
