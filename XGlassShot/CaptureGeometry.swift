import Foundation
import CoreGraphics

enum CaptureGeometry {
    static func selection(start: CGPoint, end: CGPoint, bounds: CGRect) -> CGRect {
        guard [start.x, start.y, end.x, end.y].allSatisfy({ $0.isFinite }) else { return .zero }
        let rect = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                          width: abs(end.x - start.x), height: abs(end.y - start.y))
        let clipped = rect.intersection(bounds)
        return clipped.isNull ? .zero : clipped
    }

    static func displayID(expected: UInt32?, available: [UInt32]) throws -> UInt32 {
        guard let expected, available.contains(expected) else { throw CaptureGeometryError.displayUnavailable }
        return expected
    }

    static func region(_ region: CGRect, in bounds: CGRect) throws -> CGRect {
        guard [region.origin.x, region.origin.y, region.width, region.height].allSatisfy({ $0.isFinite }),
              region.width >= 1, region.height >= 1, bounds.contains(region) else {
            throw CaptureGeometryError.invalidRegion
        }
        return region
    }
}

enum CaptureGeometryError: LocalizedError {
    case displayUnavailable, invalidRegion

    var errorDescription: String? {
        switch self {
        case .displayUnavailable: return "The selected display is unavailable. Please select an area again."
        case .invalidRegion: return "The selected area is outside the display. Please select an area again."
        }
    }
}
