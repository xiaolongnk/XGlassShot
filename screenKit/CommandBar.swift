import SwiftUI

struct CommandBar: View {
    @ObservedObject private var shortcutsManager = ShortcutsManager.shared
    @ObservedObject private var overlayManager = OverlayManager.shared
    @State private var hoveredButton: ButtonType?
    @State private var showPrefixEditor = false
    
    enum ButtonType {
        case record
        case screenshot
        case settings
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Record Button
            Button(action: {
                overlayManager.showSelectionOverlay()
            }) {
                Image(systemName: "record.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(hoveredButton == .record ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hoveredButton == .record)
            .onHover { isHovering in
                hoveredButton = isHovering ? .record : nil
            }
            
            // Screenshot Button
            Button(action: {
                overlayManager.showScreenshotOverlay()
            }) {
                Image(systemName: "camera.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(hoveredButton == .screenshot ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hoveredButton == .screenshot)
            .onHover { isHovering in
                hoveredButton = isHovering ? .screenshot : nil
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(GlassView(material: .hudWindow, blendingMode: .withinWindow))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showPrefixEditor) {
            PrefixEditorView(prefix: $shortcutsManager.currentPrefix)
        }
    }
}

struct PrefixEditorView: View {
    @Binding var prefix: String
    @Environment(\.dismiss) var dismiss
    @State private var newPrefix: String
    
    init(prefix: Binding<String>) {
        _prefix = prefix
        _newPrefix = State(initialValue: prefix.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Prefix")
                .font(.title2)
                .fontWeight(.semibold)
            
            TextField("Prefix", text: $newPrefix)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 16, design: .monospaced))
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    prefix = newPrefix
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}
