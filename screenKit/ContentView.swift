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
            Color(nsColor: NSColor(white: 0.12, alpha: 1.0))
                .ignoresSafeArea()

            // Frosted glass overlay
            VisualEffectBackground()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Top Spacer to push content down
                Spacer()

                // Main Feature: Capture Preview
                CapturePreviewView(storageManager: storageManager)
                    .padding(.horizontal, 40) // Add horizontal constraint

                // Primary Actions
                HStack(spacing: 20) {
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

                Spacer()

                // Integrated Settings Dock
                SettingsDock(storageManager: storageManager, shortcutsManager: shortcutsManager)
                    .padding(.bottom, 30)
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
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.15), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                if let thumbnail = storageManager.lastCaptureThumbnail {
                    // Content: Thumbnail
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(8)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Content: Placeholder (Ready State)
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.cyan.opacity(0.15), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "camera.aperture")
                                .font(.system(size: 56, weight: .thin))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        Text("Ready to Capture")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(0.5)
                    }
                }
                
                // Interaction Hint Overlay
                if isHovered && storageManager.lastCaptureThumbnail != nil {
                    ZStack {
                        Color.black.opacity(0.2)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "folder.fill")
                            Text("Reveal File")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        .shadow(radius: 4)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .frame(height: 240) // Fixed height for consistent layout
            .frame(maxWidth: .infinity)
            .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
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
            HStack(spacing: 14) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(color.opacity(isHovered ? 0.25 : 0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                }
                .overlay(
                    Circle()
                        .stroke(color.opacity(isHovered ? 0.6 : 0.0), lineWidth: 1)
                )
                
                // Text Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(shortcut)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                // Chevron hint
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(isHovered ? 0.4 : 0.1))
                    .offset(x: isHovered ? 3 : 0)
            }
            .padding(10)
            .padding(.trailing, 10)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white.opacity(isHovered ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(isHovered ? 0.2 : 0.08), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .frame(maxWidth: 180) // Limit width for compact look
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Settings Dock (Extracted for cleanliness)

struct SettingsDock: View {
    @ObservedObject var storageManager: StorageManager
    @ObservedObject var shortcutsManager: ShortcutsManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Path & Prefix Group
            HStack(spacing: 0) {
                // Save Path
                Button(action: {
                     Task { await storageManager.selectSaveDirectory() }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.cyan.opacity(0.8))
                        Text(storageManager.defaultSaveDirectory.lastPathComponent)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .frame(height: 20)
                    .background(Color.white.opacity(0.1))
                
                // Prefix
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.purple.opacity(0.8))
                        .font(.system(size: 12))
                    
                    TextField("Prefix", text: $shortcutsManager.currentPrefix)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .frame(width: 80)
                }
                .padding(.horizontal, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
            
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
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Toggles Group
            HStack(spacing: 4) {
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
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
        }
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
