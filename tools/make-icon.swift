// Renders the menu-bar icon: a rounded square with "VN" knocked out.
import AppKit

func rep(_ px: Int) -> NSBitmapImageRep {
    let r = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                             isPlanar: false, colorSpaceName: .deviceRGB,
                             bytesPerRow: 0, bitsPerPixel: 0)!
    r.size = NSSize(width: 16, height: 16)
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: r)!
    NSGraphicsContext.current = ctx
    NSColor.black.setFill()
    NSBezierPath(roundedRect: NSRect(x: 0.5, y: 1.5, width: 15, height: 13), xRadius: 3, yRadius: 3).fill()
    ctx.compositingOperation = .destinationOut
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 8.5, weight: .heavy),
        .foregroundColor: NSColor.black,
    ]
    let s = "VN" as NSString
    let size = s.size(withAttributes: attrs)
    s.draw(at: NSPoint(x: (16 - size.width) / 2, y: (16 - size.height) / 2 + 0.5), withAttributes: attrs)
    NSGraphicsContext.restoreGraphicsState()
    return r
}

let img = NSImage(size: NSSize(width: 16, height: 16))
img.addRepresentation(rep(16))
img.addRepresentation(rep(32))
try! img.tiffRepresentation!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
