import SwiftUI

struct CapturePreviewView: View {
    @ObservedObject var storageManager: StorageManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    
    var body: some View {
        Button(action: { storageManager.revealLastCapture() }) {
            ZStack {
                // Background Frame
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.cardFill(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Theme.cardBorder(for: colorScheme), lineWidth: 1)
                    )
                    .shadow(
                        color: Theme.cardShadow(for: colorScheme),
                        radius: Theme.cardShadowRadius(for: colorScheme),
                        x: 0, 
                        y: 15
                    )
                
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
                        
                        Text("ready_to_capture".localized)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.textSecondary(for: colorScheme))
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
                            Text("reveal_file".localized)
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
        .help("Click to reveal file in Finder")
    }
}
