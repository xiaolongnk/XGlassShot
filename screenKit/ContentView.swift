//
//  ContentView.swift
//  screenKit
//
//  Created by rex on 2026/1/11.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var shortcutsManager = ShortcutsManager.shared
    @ObservedObject private var overlayManager = OverlayManager.shared
    @ObservedObject private var storageManager = StorageManager.shared
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Dark base background (ensures visibility)
            Color(nsColor: NSColor(white: 0.12, alpha: 1.0))
                .ignoresSafeArea()

            // Frosted glass overlay
            VisualEffectBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Command Bar
                CommandBar()
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                Spacer()

                // Main Status Area
                StatusView(storageManager: storageManager)

                Spacer()

                // Recent Capture Preview
                if storageManager.lastCaptureURL != nil {
                    RecentCaptureView(storageManager: storageManager)
                        .padding(.bottom, 30)
                }

                // Settings Button
                Button(action: { showSettings = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14, weight: .medium))
                        Text("Settings")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.1))
                    )
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(width: 600, height: 550)
        }
        .onAppear {
            setupSelectionOverlay()
        }
    }

    private func setupSelectionOverlay() {
        let overlay = SelectionOverlay()
        OverlayManager.shared.setSelectionOverlay(overlay)
    }
}

// MARK: - Visual Effect Background

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .withinWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(white: 0.1, alpha: 0.95).cgColor
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Status View

struct StatusView: View {
    @ObservedObject var storageManager: StorageManager
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            // Animated aperture icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                // Icon with gradient
                Image(systemName: "camera.aperture")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(isAnimating ? 30 : 0))
            }
            .animation(
                .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }

            // Title
            VStack(spacing: 8) {
                Text("ScreenKit")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Ready to capture")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Shortcuts hints
            VStack(spacing: 12) {
                ShortcutHint(icon: "video.fill", shortcut: "⌘⇧1", label: "Record Screen")
                ShortcutHint(icon: "camera.fill", shortcut: "⌘⇧2", label: "Screenshot")
                ShortcutHint(icon: "sparkles", shortcut: "⌘⇧Q", label: "Toggle Quality")
            }
            .padding(.top, 8)
        }
    }
}

struct ShortcutHint: View {
    let icon: String
    let shortcut: String
    let label: String
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.cyan.opacity(0.8))
                .frame(width: 20)

            Text(shortcut)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.15))
                )

            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            Spacer()
        }
        .frame(width: 220)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(isHovered ? 0.08 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Recent Capture View

struct RecentCaptureView: View {
    @ObservedObject var storageManager: StorageManager
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Recent Capture")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(1)

            Button(action: { storageManager.revealLastCapture() }) {
                ZStack {
                    // Thumbnail
                    if let thumbnail = storageManager.lastCaptureThumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 90)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(.white.opacity(0.05))
                            .frame(width: 140, height: 90)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.2))
                            )
                    }

                    // Hover overlay
                    if isHovered {
                        Rectangle()
                            .fill(.black.opacity(0.4))
                            .overlay(
                                Image(systemName: "arrow.up.forward.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 140, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.spring(response: 0.3), value: isHovered)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovered = $0 }

            // Filename
            if let url = storageManager.lastCaptureURL {
                Text(url.lastPathComponent)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 160)
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject private var shortcutsManager = ShortcutsManager.shared
    @ObservedObject private var storageManager = StorageManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Dark base background
            Color(nsColor: NSColor(white: 0.12, alpha: 1.0))
                .ignoresSafeArea()

            VisualEffectBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Storage Section
                    SettingsSection(title: "Storage", icon: "folder.fill") {
                        VStack(alignment: .leading, spacing: 16) {
                            // Save Directory
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Save Location")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))

                                HStack {
                                    Text(storageManager.defaultSaveDirectory.path)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.cyan)
                                        .lineLimit(1)
                                        .truncationMode(.middle)

                                    Spacer()

                                    Button("Change") {
                                        Task {
                                            await storageManager.selectSaveDirectory()
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.black.opacity(0.3))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                                )
                            }

                            // Always Ask Toggle
                            Toggle(isOn: $storageManager.alwaysAskWhereToSave) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Always ask where to save")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Show save dialog for each capture")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .cyan))

                            // Sound Toggle
                            Toggle(isOn: $storageManager.playCaptureSound) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Play capture sound")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Shutter sound on screenshot")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .cyan))
                        }
                    }

                    // Capture Section
                    SettingsSection(title: "Capture", icon: "camera.fill") {
                        VStack(alignment: .leading, spacing: 16) {
                            // Prefix
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Filename Prefix")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))

                                TextField("Prefix", text: $shortcutsManager.currentPrefix)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.black.opacity(0.3))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            }

                            // Quality
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Capture Quality")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))

                                HStack(spacing: 12) {
                                    QualityButton(
                                        quality: .quick,
                                        isSelected: shortcutsManager.captureQuality == .quick,
                                        action: { shortcutsManager.captureQuality = .quick }
                                    )
                                    QualityButton(
                                        quality: .high,
                                        isSelected: shortcutsManager.captureQuality == .high,
                                        action: { shortcutsManager.captureQuality = .high }
                                    )
                                }
                            }
                        }
                    }

                    // Shortcuts Section
                    SettingsSection(title: "Shortcuts", icon: "keyboard") {
                        VStack(spacing: 0) {
                            ShortcutSettingRow(action: "Record Screen", shortcut: "⌘⇧1")
                            ShortcutSettingRow(action: "Screenshot", shortcut: "⌘⇧2")
                            ShortcutSettingRow(action: "Toggle Quality", shortcut: "⌘⇧Q")
                            ShortcutSettingRow(action: "Change Path", shortcut: "⌘⇧P")
                            ShortcutSettingRow(action: "Change Prefix", shortcut: "⌘⇧L")
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.black.opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                .padding(32)
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.cyan)

                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct QualityButton: View {
    let quality: CaptureQuality
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: quality == .quick ? "hare" : "sparkles")
                    .font(.system(size: 20, weight: .medium))

                Text(quality.displayName)
                    .font(.system(size: 12, weight: .semibold))

                Text(quality == .quick ? "1x Scale" : "2x Scale")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .foregroundColor(isSelected ? .cyan : .white.opacity(0.7))
            .frame(width: 100, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .cyan.opacity(0.2) : .white.opacity(isHovered ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .cyan.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

struct ShortcutSettingRow: View {
    let action: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(action)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Text(shortcut)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.1))
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.white.opacity(0.05)),
            alignment: .bottom
        )
    }
}
