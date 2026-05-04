import AppKit
import Foundation

let canvas = CGSize(width: 1024, height: 500)
let inputPath = "/Users/victor/Downloads/Play Store Promotion/howlong_screenshot_1_1242x2208.png"
let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("store-assets/play-feature-graphic.jpg")

struct Theme {
    static let ink = NSColor(calibratedRed: 0.00, green: 0.23, blue: 0.17, alpha: 1)
    static let ring = NSColor(calibratedRed: 0.00, green: 0.34, blue: 0.26, alpha: 0.34)
    static let accent = NSColor(calibratedRed: 0.00, green: 0.82, blue: 0.68, alpha: 1)
    static let white = NSColor.white
    static let mutedWhite = NSColor(calibratedWhite: 1, alpha: 0.88)
}

func font(_ size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

func paragraph(lineHeight: CGFloat? = nil) -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = .left
    style.lineBreakMode = .byWordWrapping
    if let lineHeight {
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
    }
    return style
}

func drawText(
    _ text: String,
    in rect: CGRect,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: NSColor = Theme.white,
    lineHeight: CGFloat? = nil
) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font(size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph(lineHeight: lineHeight)
    ]
    (text as NSString).draw(in: rect, withAttributes: attributes)
}

func fillRounded(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func drawRing(center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
    let rect = CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
    )
    let path = NSBezierPath(ovalIn: rect)
    path.lineWidth = lineWidth
    Theme.ring.setStroke()
    path.stroke()
}

func cropImage(_ image: NSImage, rect: CGRect) -> NSImage? {
    guard
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
        let cropped = cgImage.cropping(to: rect)
    else {
        return nil
    }
    return NSImage(cgImage: cropped, size: rect.size)
}

guard let source = NSImage(contentsOfFile: inputPath) else {
    fatalError("Could not read \(inputPath)")
}

let phoneCrop = CGRect(x: 282, y: 664, width: 648, height: 1468)
guard let phoneImage = cropImage(source, rect: phoneCrop) else {
    fatalError("Could not crop phone image")
}

let image = NSImage(size: canvas)
image.lockFocus()

Theme.ink.setFill()
CGRect(origin: .zero, size: canvas).fill()

drawRing(center: CGPoint(x: 850, y: 438), radius: 170, lineWidth: 82)
drawRing(center: CGPoint(x: 1015, y: 88), radius: 245, lineWidth: 92)

drawText(
    "HowLong",
    in: CGRect(x: 72, y: 350, width: 300, height: 48),
    size: 36,
    weight: .bold,
    color: Theme.accent
)
drawText(
    "Track the\nlast time.",
    in: CGRect(x: 72, y: 205, width: 420, height: 150),
    size: 66,
    weight: .bold,
    lineHeight: 68
)
drawText(
    "See exactly how long ago\nyou did anything.",
    in: CGRect(x: 76, y: 112, width: 410, height: 94),
    size: 32,
    weight: .medium,
    color: Theme.mutedWhite,
    lineHeight: 35
)
fillRounded(CGRect(x: 76, y: 76, width: 72, height: 8), radius: 4, color: Theme.accent)

let phoneRect = CGRect(x: 594, y: -120, width: 300, height: 680)
phoneImage.draw(in: phoneRect)

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff)
else {
    fatalError("Could not create bitmap")
}

guard let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.94]) else {
    fatalError("Could not encode JPEG")
}

try jpeg.write(to: outputURL)
print("Generated \(outputURL.path)")
