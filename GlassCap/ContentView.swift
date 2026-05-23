//
//  ContentView.swift
//  GlassCap
//
//  Created by rex on 2026/1/11.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ObservedObject private var shortcutsManager = ShortcutsManager.shared
    @ObservedObject private var overlayManager = OverlayManager.shared
    @ObservedObject private var storageManager = StorageManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        ZStack {
            // Dynamic Background
            ZStack {
                Theme.background(for: colorScheme).ignoresSafeArea()
                
                // Ambient Gradients
                Theme.ambientGradientTop(for: colorScheme).ignoresSafeArea()
                Theme.ambientGradientBottom(for: colorScheme).ignoresSafeArea()
            }

            // Frosted glass overlay
            if reduceTransparency {
                Theme.background(for: colorScheme).ignoresSafeArea()
                    .onTapGesture {
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
            } else {
                VisualEffectBackground(colorScheme: colorScheme)
                    .ignoresSafeArea()
                    .onTapGesture {
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
            }

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                // Main Feature: Capture Preview — focal point in upper third
                CapturePreviewView(storageManager: storageManager)
                    .padding(.horizontal, 28)

                Spacer(minLength: 24)

                // Primary Actions
                HStack(spacing: 16) {
                    // Record Button
                    HeroActionButton(
                        icon: "record.circle.fill",
                        label: "record".localized,
                        shortcut: "⌘⇧1",
                        color: .red,
                        description: "Select an area to record screen",
                        action: { OverlayManager.shared.showSelectionOverlay() }
                    )

                    // Screenshot Button
                    HeroActionButton(
                        icon: "camera.fill",
                        label: "capture".localized,
                        shortcut: "⌘⇧2",
                        color: .accentColor,
                        description: "Select an area to take a screenshot",
                        action: { OverlayManager.shared.showScreenshotOverlay() }
                    )
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 20)

                // Floating Settings Dock
                SettingsDock(storageManager: storageManager, shortcutsManager: shortcutsManager)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Extracted Components
// CapturePreviewView, HeroActionButton, SettingsDock, VisualEffectBackground, DockToggle
// have been moved to their own files.
