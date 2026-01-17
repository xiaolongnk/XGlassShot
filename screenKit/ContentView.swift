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

    var body: some View {
        ZStack {
            // Dark base background (ensures visibility)
            // Dynamic Background
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Ambient Gradients
                RadialGradient(
                    colors: [Color.blue.opacity(0.12), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 1000
                )
                .ignoresSafeArea()
                
                RadialGradient(
                    colors: [Color.purple.opacity(0.1), Color.clear],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 800
                )
                .ignoresSafeArea()
            }

            // Frosted glass overlay
            VisualEffectBackground()
                .ignoresSafeArea()

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
                        label: "Record",
                        shortcut: "⌘⇧1",
                        color: .red,
                        action: { OverlayManager.shared.showSelectionOverlay() }
                    )
                    
                    // Screenshot Button
                    HeroActionButton(
                        icon: "camera.fill",
                        label: "Capture",
                        shortcut: "⌘⇧2",
                        color: .cyan,
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
        .onAppear {
            setupSelectionOverlay()
        }
    }

    private func setupSelectionOverlay() {
        let overlay = SelectionOverlay()
        OverlayManager.shared.setSelectionOverlay(overlay)
    }
}

// MARK: - Capture Preview View (Hero Component)

struct CapturePreviewView: View {
    @ObservedObject var storageManager: StorageManager
    @State private var isHovered = false
    
    var body: some View {
        Button(action: { storageManager.revealLastCapture() }) {
            ZStack {
                // Background Frame
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.1), .white.opacity(0.02)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
                
                if let thumbnail = storageManager.lastCaptureThumbnail {
                    // Content: Thumbnail
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(8)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Content: Placeholder (Ready State)
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.cyan.opacity(0.1), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 140, height: 140)
                            
                            Image(systemName: "camera.macro")
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan.opacity(0.8), .purple.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 0)
                        }
                        
                        Text("Ready to Capture")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                    }
                }
                
                // Interaction Hint Overlay
                if isHovered && storageManager.lastCaptureThumbnail != nil {
                    ZStack {
                        Color.black.opacity(0.3)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                            Text("Reveal File")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                        )
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                    }
                }
            }
            .frame(height: 260) // Slightly taller
            .frame(maxWidth: .infinity)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Refined Action Buttons

struct HeroActionButton: View {
    let icon: String
    let label: String
    let shortcut: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [color.opacity(0.6), color.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 0)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: color.opacity(0.6), radius: 4)
                }
                
                // Text Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(shortcut)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Chevron hint
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(isHovered ? 0.8 : 0.3))
                    .offset(x: isHovered ? 4 : 0)
            }
            .padding(.leading, 12)
            .padding(.trailing, 20)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.4))
            )
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(isHovered ? 0.08 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(isHovered ? 0.4 : 0.15),
                                .white.opacity(isHovered ? 0.15 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Settings Dock (Extracted for cleanliness)

struct SettingsDock: View {
    @ObservedObject var storageManager: StorageManager
    @ObservedObject var shortcutsManager: ShortcutsManager
    @ObservedObject private var launchManager = LaunchManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Path Selector
            Button(action: {
                 Task { await storageManager.selectSaveDirectory() }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.cyan)
                    Text(storageManager.defaultSaveDirectory.lastPathComponent)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .frame(height: 16)
                .background(Color.white.opacity(0.15))
            
            // Prefix Input
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .foregroundColor(.purple)
                    .font(.system(size: 12))
                
                TextField("Prefix", text: $shortcutsManager.currentPrefix)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .frame(width: 80)
            }
            .padding(.horizontal, 16)
            
            Divider()
                .frame(height: 16)
                .background(Color.white.opacity(0.15))

            // Quality Toggle
            Button(action: { shortcutsManager.toggleQuality() }) {
                HStack(spacing: 6) {
                    Image(systemName: shortcutsManager.captureQuality == .quick ? "bolt.fill" : "sparkles")
                        .foregroundColor(shortcutsManager.captureQuality == .quick ? .yellow : .cyan)
                    Text(shortcutsManager.captureQuality == .quick ? "Quick" : "High")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .frame(height: 16)
                .background(Color.white.opacity(0.15))

            // Icon Toggles
            HStack(spacing: 8) {
                DockToggle(
                    isOn: $launchManager.isAutoStartEnabled,
                    icon: "power.circle.fill", // Or "desktopcomputer"
                    activeColor: .blue
                )
                .onChange(of: launchManager.isAutoStartEnabled) { _ in
                    launchManager.toggleAutoStart()
                }
                
                DockToggle(
                    isOn: $storageManager.playCaptureSound,
                    icon: "speaker.wave.2.fill",
                    activeColor: .pink
                )
                
                DockToggle(
                    isOn: $storageManager.alwaysAskWhereToSave,
                    icon: "questionmark.folder.fill",
                    activeColor: .orange
                )
                
                DockToggle(
                    isOn: $storageManager.addScreenshotOutline,
                    icon: "square.dashed",
                    activeColor: .green
                )
            }
            .padding(.horizontal, 12)
        }
        .background(
            Capsule()
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.8))
        )
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }
}

// MARK: - Utilities

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

struct DockToggle: View {
    @Binding var isOn: Bool
    let icon: String
    let activeColor: Color
    @State private var isHovered = false

    var body: some View {
        Button(action: { isOn.toggle() }) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isOn ? activeColor : .white.opacity(0.3))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isOn ? activeColor.opacity(0.1) : .clear)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isHovered ? 0.2 : 0.0), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
    }
}
