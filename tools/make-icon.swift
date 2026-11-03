// Renders the menu-bar icon: an outlined rounded square with "V" inside,
// in the same style as the system input source icons.
import AppKit

func rep(_ px: Int) -> NSBitmapImageRep {
    let r = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                             isPlanar: false, colorSpaceName: .deviceRGB,
                             bytesPerRow: 0, bitsPerPixel: 0)!
    r.size = NSSize(width: 16, height: 16)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: r)
    NSColor.black.set()
    let box = NSBezierPath(roundedRect: NSRect(x: 1, y: 2, width: 14, height: 12), xRadius: 3, yRadius: 3)
    box.lineWidth = 1.1
    box.stroke()
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 9.5, weight: .semibold),
        .foregroundColor: NSColor.black,
    ]
    let s = "V" as NSString
    let size = s.size(withAttributes: attrs)
    s.draw(at: NSPoint(x: (16 - size.width) / 2, y: (16 - size.height) / 2 + 0.25), withAttributes: attrs)
    NSGraphicsContext.restoreGraphicsState()
    return r
}

let img = NSImage(size: NSSize(width: 16, height: 16))
img.addRepresentation(rep(16))
img.addRepresentation(rep(32))
try! img.tiffRepresentation!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
