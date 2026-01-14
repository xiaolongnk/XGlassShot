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

            VStack(spacing: 0) {
                // Top Command Bar
                Spacer()

                Spacer()

                // Main Status Area
                StatusView(storageManager: storageManager)

                Spacer()

                // Integrated Settings Dock
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
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

                Text("Ready to capture")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.5)
            }

            // Hero Actions
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
            .padding(.top, 20)
        }
    }
}

struct HeroActionButton: View {
    let icon: String
    let label: String
    let shortcut: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isHovered ? 0.2 : 0.1))
                        .frame(width: 80, height: 80)
                        
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(color)
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                }
                .shadow(color: color.opacity(isHovered ? 0.3 : 0.0), radius: 15, x: 0, y: 0)
                
                VStack(spacing: 4) {
                    Text(label)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(shortcut)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .frame(width: 140, height: 160)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(isHovered ? 0.08 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(isHovered ? 0.15 : 0.05), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

struct ShortcutHint: View {
    let icon: String
    let shortcut: String
    let label: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
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
                
                // Angle bracket to imply action
                if isHovered {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(width: 240) // Slightly wider
            .padding(.horizontal, 16)
            .padding(.vertical, 12) // Taller touch area
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(isHovered ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(isHovered ? 0.2 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
