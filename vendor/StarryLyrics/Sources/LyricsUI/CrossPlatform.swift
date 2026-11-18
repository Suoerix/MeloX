#if canImport(UIKit)
import UIKit

// The upstream component is AppKit-based; on iOS the same names map to UIKit.
public typealias NSFont = UIFont
public typealias NSColor = UIColor
public typealias NSView = UIView

extension NSColor {
    /// NSColor's `brightnessComponent`, for a tint of any colour space.
    var lyricBrightnessComponent: CGFloat {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 1, alpha: CGFloat = 0
        _ = getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return brightness
    }

    /// NSColor's `usingColorSpace(.sRGB) ?? .white`.
    var lyricSRGBTint: NSColor { self }
}

extension NSValue {
    /// NSValue's `NSValue(point:)` constructor (UIKit spells it `cgPoint:`).
    convenience init(point: CGPoint) {
        self.init(cgPoint: point)
    }

    /// NSValue's macOS accessors (UIKit prefixes theirs with `cg`).
    var rectValue: CGRect { cgRectValue }
    var pointValue: CGPoint { cgPointValue }
    var sizeValue: CGSize { cgSizeValue }
}
#else
import AppKit

extension NSColor {
    var lyricBrightnessComponent: CGFloat { usingColorSpace(.sRGB)?.brightnessComponent ?? 1 }
    var lyricSRGBTint: NSColor { usingColorSpace(.sRGB) ?? .white }
}
#endif

/// Cross-platform `NSValue(point:)`.
func CrossPlatformValue(point: CGPoint) -> NSValue {
    NSValue(point: point)
}
