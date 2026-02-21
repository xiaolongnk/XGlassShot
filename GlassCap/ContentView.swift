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

            VStack(spacing: 32) {
                // Top Spacer to push content down
                Spacer()

                // Main Feature: Capture Preview
                CapturePreviewView(storageManager: storageManager)
                    .padding(.horizontal, 40)

                // Primary Actions
                HStack(spacing: 24) {
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
                        color: .cyan,
                        description: "Select an area to take a screenshot",
                        action: { OverlayManager.shared.showScreenshotOverlay() }
                    )
                }
                .padding(.horizontal, 40)

                Spacer()

                // Integrated Settings Dock
                SettingsDock(storageManager: storageManager, shortcutsManager: shortcutsManager)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Extracted Components
// CapturePreviewView, HeroActionButton, SettingsDock, VisualEffectBackground, DockToggle
// have been moved to their own files.
