import SwiftUI

struct DashboardSettingsView: View {
    @State private var currentPrefix: String = "ui_v2_"
    @State private var currentSavePath: String = "~/Desktop/ScreenRecordings"
    
    var body: some View {
        GlassView(material: .hudWindow, blendingMode: .withinWindow) {
            VStack(alignment: .leading, spacing: 24) {
                // Top Section - Status
                VStack(alignment: .leading, spacing: 16) {
                    Text("Status")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Prefix Badge
                    HStack(spacing: 12) {
                        Text("Prefix")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(currentPrefix)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Save Path Code Snippet
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Save Path")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack {
                            Text(currentSavePath)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.green)
                                .textSelection(.enabled)
                            
                            Spacer()
                            
                            Button(action: {
                                // Change path action
                            }) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.4))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Bottom Section - Shortcuts Map
                VStack(alignment: .leading, spacing: 16) {
                    Text("Global Shortcuts")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Shortcuts Grid
                    VStack(spacing: 0) {
                        // Header Row
                        HStack(spacing: 0) {
                            Text("Action")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Shortcut")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.2))
                        
                        // Shortcut Rows
                        ShortcutRow(action: "Capture Zone", shortcut: "⌘⇧1")
                        ShortcutRow(action: "Quick Change Path", shortcut: "⌘⇧P")
                        ShortcutRow(action: "Quick Change Prefix", shortcut: "⌘⇧L")
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.2))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .frame(width: 600)
    }
}

struct ShortcutRow: View {
    let action: String
    let shortcut: String
    
    var body: some View {
        HStack(spacing: 0) {
            Text(action)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ShortcutBadge(shortcut: shortcut)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}

struct ShortcutBadge: View {
    let shortcut: String
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(parseShortcut(shortcut), id: \.self) { key in
                Text(key)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private func parseShortcut(_ shortcut: String) -> [String] {
        // Handle symbol-based shortcuts
        if shortcut.contains("⌘") || shortcut.contains("⇧") {
            return shortcut.components(separatedBy: CharacterSet.whitespaces)
                .filter { !$0.isEmpty }
        }
        // For text-based shortcuts like "Cmd+Shift+1"
        return shortcut.components(separatedBy: "+")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
