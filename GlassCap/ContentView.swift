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
                // Zone 1: Compact header
                CompactHeaderView()

                // Zone 2: Preview + action buttons (natural height, top-anchored)
                CapturePreviewView(storageManager: storageManager)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                Spacer(minLength: 0)

                // Zone 3: Capture action buttons (Record + Capture side-by-side)
                CaptureControlsRow()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                // Zone 4: Thin status bar
                CompactStatusBar(storageManager: storageManager, shortcutsManager: shortcutsManager)
                    .frame(height: 36)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Zone 1: Compact Header

struct CompactHeaderView: View {
    @State private var showSettings = false
    @ObservedObject private var storageManager = StorageManager.shared
    @ObservedObject private var shortcutsManager = ShortcutsManager.shared

    private var appTitle: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info["CFBundleVersion"] as? String ?? "unknown"
        return "GlassCap \(version) (\(build))"
    }

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(appTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .help("Source: " + (Bundle.main.infoDictionary?["GlassCapSourceRevision"] as? String ?? "unknown"))
            }
            Spacer()
            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gear")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettings, arrowEdge: .top) {
                SettingsDock(storageManager: storageManager, shortcutsManager: shortcutsManager)
                    .frame(width: 480)
                    .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Zone 3: Capture Controls Row

struct CaptureControlsRow: View {
    @ObservedObject private var overlayManager = OverlayManager.shared
    var body: some View {
        HStack(spacing: 10) {
            // Record
            Button(action: {
                if overlayManager.isRecording { Task { await overlayManager.stopRecording() } }
                else { overlayManager.showSelectionOverlay() }
            }) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.red.opacity(0.15)).frame(width: 28, height: 28)
                        Image(systemName: "record.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.red)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(overlayManager.isRecording ? "Stop Recording".localized : "Record".localized)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Text("⌘⇧1")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .disabled(overlayManager.isBusy && !overlayManager.isRecording)

            // Capture
            Button(action: { OverlayManager.shared.showScreenshotOverlay() }) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.cyan.opacity(0.15)).frame(width: 28, height: 28)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.cyan)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Capture")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Text("⌘⇧2")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .disabled(overlayManager.isBusy)
        }
    }
}

// MARK: - Zone 4: Compact Status Bar

struct CompactStatusBar: View {
    @ObservedObject var storageManager: StorageManager
    @ObservedObject var shortcutsManager: ShortcutsManager
    @State private var showSettingsPopover = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            // Folder
            statusChip(
                icon: "folder.fill",
                label: storageManager.defaultSaveDirectory.lastPathComponent,
                color: .green
            )
            Divider().frame(height: 16)
            // Prefix tag
            statusChip(
                icon: "tag.fill",
                label: shortcutsManager.currentPrefix.isEmpty ? "—" : shortcutsManager.currentPrefix,
                color: .purple
            )
            Divider().frame(height: 16)
            // Quality
            statusChip(
                icon: "sparkles",
                label: shortcutsManager.captureQuality.displayName,
                color: .yellow
            )

            Spacer()

            // Settings popover trigger
            Button(action: { showSettingsPopover.toggle() }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettingsPopover, arrowEdge: .bottom) {
                SettingsDock(storageManager: storageManager, shortcutsManager: shortcutsManager)
                    .frame(width: 480)
                    .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 16)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    @ViewBuilder
    private func statusChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
    }
}

// MARK: - Extracted Components
// CapturePreviewView, HeroActionButton, SettingsDock, VisualEffectBackground, DockToggle
// have been moved to their own files.
