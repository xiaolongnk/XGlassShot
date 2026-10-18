import AppKit
import CoreGraphics

@available(macOS 12.3, *)
struct BeautifulExportCompositor {

    struct Options {
        var padding: CGFloat = 48
        var cornerRadius: CGFloat = 12
        var shadowRadius: CGFloat = 24
        var shadowOpacity: CGFloat = 0.35
        var backgroundStyle: BackgroundStyle = .gradient(.mesh1)

        enum BackgroundStyle {
            case gradient(GradientPreset)
            case solid(NSColor)
        }

        enum GradientPreset: CaseIterable, Identifiable {
            case mesh1, mesh2, mesh3, mesh4, dark, light
            var id: Self { self }
            var label: String {
                switch self {
                case .mesh1: return "Ocean"
                case .mesh2: return "Sunset"
                case .mesh3: return "Forest"
                case .mesh4: return "Aurora"
                case .dark: return "Obsidian"
                case .light: return "Cloud"
                }
            }
            var colors: [NSColor] {
                switch self {
                case .mesh1: return [NSColor(red: 0.05, green: 0.15, blue: 0.35, alpha: 1),
                                     NSColor(red: 0.15, green: 0.35, blue: 0.65, alpha: 1)]
                case .mesh2: return [NSColor(red: 0.55, green: 0.15, blue: 0.25, alpha: 1),
                                     NSColor(red: 0.95, green: 0.55, blue: 0.2, alpha: 1)]
                case .mesh3: return [NSColor(red: 0.05, green: 0.3, blue: 0.15, alpha: 1),
                                     NSColor(red: 0.2, green: 0.55, blue: 0.35, alpha: 1)]
                case .mesh4: return [NSColor(red: 0.25, green: 0.05, blue: 0.45, alpha: 1),
                                     NSColor(red: 0.05, green: 0.65, blue: 0.75, alpha: 1)]
                case .dark: return [NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1),
                                    NSColor(red: 0.14, green: 0.14, blue: 0.18, alpha: 1)]
                case .light: return [NSColor(red: 0.92, green: 0.94, blue: 0.98, alpha: 1),
                                     NSColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1)]
                }
            }
        }
    }

    static func compose(image: NSImage, options: Options) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let srcW = CGFloat(cgImage.width)
        let srcH = CGFloat(cgImage.height)
        let pad = options.padding
        let canvasW = srcW + pad * 2
        let canvasH = srcH + pad * 2

        guard let ctx = CGContext(
            data: nil, width: Int(canvasW), height: Int(canvasH),
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let canvasRect = CGRect(x: 0, y: 0, width: canvasW, height: canvasH)
        let imageRect = CGRect(x: pad, y: pad, width: srcW, height: srcH)

        // Background
        switch options.backgroundStyle {
        case .gradient(let preset):
            drawGradient(in: ctx, rect: canvasRect, colors: preset.colors)
        case .solid(let color):
            ctx.setFillColor(color.cgColor)
            ctx.fill(canvasRect)
        }

        // Shadow under screenshot
        ctx.saveGState()
        let shadowColor = NSColor.black.withAlphaComponent(options.shadowOpacity).cgColor
        ctx.setShadow(offset: CGSize(width: 0, height: -options.shadowRadius * 0.3),
                      blur: options.shadowRadius, color: shadowColor)

        // Clip to rounded corners
        let clipPath = CGPath(roundedRect: imageRect,
                              cornerWidth: options.cornerRadius,
                              cornerHeight: options.cornerRadius,
                              transform: nil)
        ctx.addPath(clipPath)
        ctx.clip()
        ctx.draw(cgImage, in: imageRect)
        ctx.restoreGState()

        guard let result = ctx.makeImage() else { return nil }
        return NSImage(cgImage: result, size: NSSize(width: canvasW, height: canvasH))
    }

    private static func drawGradient(in ctx: CGContext, rect: CGRect, colors: [NSColor]) {
        guard colors.count >= 2,
              let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors.map(\.cgColor) as CFArray,
                locations: nil
              ) else { return }
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: rect.minX, y: rect.maxY),
                               end: CGPoint(x: rect.maxX, y: rect.minY),
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }
}
