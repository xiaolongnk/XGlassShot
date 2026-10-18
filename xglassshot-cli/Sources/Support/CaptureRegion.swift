import Foundation

enum CaptureRegion {
    struct InvalidRegion: LocalizedError {
        var errorDescription: String? { "Invalid --region. Use x,y,width,height in top-left points, fully inside the selected display with positive dimensions." }
    }
    static func parse(_ value: String?, size: CGSize) throws -> CGRect {
        let bounds = CGRect(origin: .zero, size: size)
        guard let value else { return bounds }
        let parts = value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 4, let x = Int(parts[0]), let y = Int(parts[1]),
              let width = Int(parts[2]), let height = Int(parts[3]), width > 0, height > 0 else { throw InvalidRegion() }
        let rect = CGRect(x: x, y: y, width: width, height: height)
        guard bounds.contains(rect) else { throw InvalidRegion() }
        return rect
    }
}
