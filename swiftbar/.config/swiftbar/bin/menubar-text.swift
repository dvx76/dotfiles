// Renders colored menu bar text to a base64 PNG for SwiftBar's image= parameter.
// Usage: menubar-text <Dark|Light> <text> <hex|-> [<text> <hex|-> ...]
// "-" means the normal menu bar text color; "~" means the dimmed secondary color.
import AppKit

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 3, (args.count - 1) % 2 == 0 else {
    FileHandle.standardError.write("usage: menubar-text <Dark|Light> <text> <hex|-|~> ...\n".data(using: .utf8)!)
    exit(1)
}
let dark = args[0].lowercased() == "dark"
let base = dark ? NSColor.white : NSColor.black.withAlphaComponent(0.85)
let dim = base.withAlphaComponent(dark ? 0.6 : 0.5)

func color(_ s: String) -> NSColor {
    if s == "-" { return base }
    if s == "~" { return dim }
    var h = s; if h.hasPrefix("#") { h.removeFirst() }
    guard h.count == 6, let v = UInt32(h, radix: 16) else { return base }
    return NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                   blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
let text = NSMutableAttributedString()
var i = 1
while i + 1 < args.count {
    text.append(NSAttributedString(string: args[i], attributes: [.font: font, .foregroundColor: color(args[i + 1])]))
    i += 2
}

let scale: CGFloat = 2
let textSize = text.size()
let size = NSSize(width: ceil(textSize.width), height: 18)
guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                 colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { exit(1) }
rep.size = size  // points, so the PNG carries 144 dpi and displays at retina size
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
text.draw(at: NSPoint(x: 0, y: (size.height - textSize.height) / 2))
NSGraphicsContext.restoreGraphicsState()
guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
print(png.base64EncodedString())
