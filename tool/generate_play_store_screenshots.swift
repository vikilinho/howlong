import AppKit
import Foundation

let canvas = CGSize(width: 1080, height: 1920)
let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("store-assets/play-screenshots", isDirectory: true)

try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

struct Theme {
    static let ink = NSColor(calibratedRed: 0.02, green: 0.09, blue: 0.08, alpha: 1)
    static let muted = NSColor(calibratedRed: 0.39, green: 0.46, blue: 0.44, alpha: 1)
    static let mint = NSColor(calibratedRed: 0.93, green: 0.98, blue: 0.96, alpha: 1)
    static let mintStrong = NSColor(calibratedRed: 0.75, green: 0.94, blue: 0.87, alpha: 1)
    static let card = NSColor(calibratedRed: 0.98, green: 0.995, blue: 0.985, alpha: 1)
    static let border = NSColor(calibratedRed: 0.80, green: 0.88, blue: 0.85, alpha: 1)
    static let green = NSColor(calibratedRed: 0.00, green: 0.20, blue: 0.15, alpha: 1)
    static let red = NSColor(calibratedRed: 0.76, green: 0.06, blue: 0.04, alpha: 1)
    static let white = NSColor.white
}

struct Feature {
    let filename: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let renderPhone: (CGRect) -> Void
}

func font(_ size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

func paragraph(alignment: NSTextAlignment = .left, lineHeight: CGFloat? = nil) -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    style.lineBreakMode = .byWordWrapping
    if let lineHeight {
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
    }
    return style
}

func drawingRect(_ rect: CGRect) -> CGRect {
    CGRect(
        x: rect.minX,
        y: canvas.height - rect.minY - rect.height,
        width: rect.width,
        height: rect.height
    )
}

func drawingPoint(_ point: CGPoint) -> CGPoint {
    CGPoint(x: point.x, y: canvas.height - point.y)
}

func drawText(
    _ text: String,
    in rect: CGRect,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: NSColor = Theme.ink,
    alignment: NSTextAlignment = .left,
    lineHeight: CGFloat? = nil
) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font(size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph(alignment: alignment, lineHeight: lineHeight)
    ]
    (text as NSString).draw(in: drawingRect(rect), withAttributes: attributes)
}

func fillRounded(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: drawingRect(rect), xRadius: radius, yRadius: radius).fill()
}

func strokeRounded(_ rect: CGRect, radius: CGFloat, color: NSColor, lineWidth: CGFloat = 2) {
    color.setStroke()
    let path = NSBezierPath(roundedRect: drawingRect(rect), xRadius: radius, yRadius: radius)
    path.lineWidth = lineWidth
    path.stroke()
}

func drawCircle(_ rect: CGRect, color: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 2) {
    let path = NSBezierPath(ovalIn: drawingRect(rect))
    color.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func drawCheck(center: CGPoint, size: CGFloat, color: NSColor = Theme.white, lineWidth: CGFloat = 8) {
    let center = drawingPoint(center)
    let path = NSBezierPath()
    path.move(to: CGPoint(x: center.x - size * 0.35, y: center.y + size * 0.02))
    path.line(to: CGPoint(x: center.x - size * 0.10, y: center.y - size * 0.24))
    path.line(to: CGPoint(x: center.x + size * 0.38, y: center.y + size * 0.30))
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    color.setStroke()
    path.stroke()
}

func drawPhoneFrame(_ rect: CGRect, render: (CGRect) -> Void) {
    fillRounded(rect, radius: 70, color: Theme.ink.withAlphaComponent(0.18))
    let shell = rect.insetBy(dx: 14, dy: 14)
    fillRounded(shell, radius: 62, color: Theme.ink)
    let screen = shell.insetBy(dx: 18, dy: 18)
    fillRounded(screen, radius: 46, color: Theme.mint)
    fillRounded(CGRect(x: screen.midX - 82, y: screen.minY + 18, width: 164, height: 22), radius: 11, color: Theme.ink)
    render(screen.insetBy(dx: 44, dy: 60))
}

func drawProgressBar(_ rect: CGRect, progress: CGFloat, color: NSColor = Theme.green) {
    fillRounded(rect, radius: rect.height / 2, color: Theme.border.withAlphaComponent(0.65))
    fillRounded(CGRect(x: rect.minX, y: rect.minY, width: rect.width * progress, height: rect.height), radius: rect.height / 2, color: color)
}

func drawMiniSquares(origin: CGPoint, active: Int, total: Int = 5) {
    for index in 0..<total {
        let color = index < active ? Theme.green : Theme.border
        fillRounded(CGRect(x: origin.x + CGFloat(index) * 34, y: origin.y, width: 25, height: 25), radius: 4, color: color)
    }
}

func drawActionCard(_ rect: CGRect, title: String, time: String, progress: CGFloat, overdue: Bool = false) {
    fillRounded(rect, radius: 28, color: Theme.white)
    strokeRounded(rect, radius: 28, color: Theme.border)
    drawCircle(CGRect(x: rect.minX + 44, y: rect.minY + 42, width: 58, height: 58), color: Theme.mintStrong)
    drawText(overdue ? "!" : "↻", in: CGRect(x: rect.minX + 60, y: rect.minY + 47, width: 28, height: 36), size: 30, weight: .bold, color: overdue ? Theme.red : Theme.green, alignment: .center)
    fillRounded(CGRect(x: rect.maxX - 158, y: rect.minY + 44, width: 96, height: 44), radius: 22, color: Theme.mint)
    drawText("LOG", in: CGRect(x: rect.maxX - 130, y: rect.minY + 55, width: 52, height: 22), size: 18, weight: .bold, color: Theme.green, alignment: .center)
    drawText(title, in: CGRect(x: rect.minX + 44, y: rect.minY + 112, width: rect.width - 88, height: 48), size: 37, weight: .semibold)
    drawText(time, in: CGRect(x: rect.minX + 44, y: rect.minY + 166, width: rect.width - 88, height: 38), size: 27, color: overdue ? Theme.red : Theme.muted)
    drawProgressBar(CGRect(x: rect.minX + 44, y: rect.maxY - 24, width: rect.width - 88, height: 9), progress: progress, color: overdue ? Theme.red : Theme.green)
}

func drawHabitCard(_ rect: CGRect, title: String, subtitle: String, streak: String, build: Bool) {
    fillRounded(rect, radius: 24, color: Theme.white)
    strokeRounded(rect, radius: 24, color: Theme.border)
    if build {
        drawCircle(CGRect(x: rect.minX + 34, y: rect.midY - 39, width: 78, height: 78), color: Theme.mintStrong)
        drawText("↗", in: CGRect(x: rect.minX + 50, y: rect.midY - 28, width: 46, height: 46), size: 42, weight: .bold, color: Theme.green, alignment: .center)
    } else {
        drawCircle(CGRect(x: rect.minX + 34, y: rect.midY - 39, width: 78, height: 78), color: Theme.green)
        drawText("✕", in: CGRect(x: rect.minX + 54, y: rect.midY - 24, width: 38, height: 38), size: 34, weight: .bold, color: Theme.white, alignment: .center)
    }
    drawText(title, in: CGRect(x: rect.minX + 140, y: rect.minY + 42, width: rect.width - 290, height: 42), size: 29, weight: .medium)
    drawText(subtitle, in: CGRect(x: rect.minX + 140, y: rect.minY + 84, width: rect.width - 290, height: 34), size: 23, color: Theme.muted)
    fillRounded(CGRect(x: rect.maxX - 144, y: rect.midY - 28, width: 94, height: 56), radius: 18, color: Theme.mint)
    drawText(streak, in: CGRect(x: rect.maxX - 126, y: rect.midY - 15, width: 58, height: 30), size: 22, weight: .bold, color: Theme.green, alignment: .center)
}

func renderToday(_ rect: CGRect) {
    drawText("HowLong", in: CGRect(x: rect.minX, y: rect.minY + 10, width: rect.width, height: 42), size: 30, weight: .bold, alignment: .center)
    drawText("Today", in: CGRect(x: rect.minX, y: rect.minY + 94, width: rect.width, height: 64), size: 54, weight: .bold)
    drawText("Know what needs your attention now.", in: CGRect(x: rect.minX, y: rect.minY + 160, width: rect.width, height: 38), size: 24, color: Theme.muted)
    drawText("Actions", in: CGRect(x: rect.minX, y: rect.minY + 240, width: rect.width, height: 46), size: 34, weight: .semibold)
    drawActionCard(CGRect(x: rect.minX, y: rect.minY + 302, width: rect.width, height: 230), title: "Drank Water", time: "42 minutes ago", progress: 0.72)
    drawActionCard(CGRect(x: rect.minX, y: rect.minY + 560, width: rect.width, height: 230), title: "Watered Plants", time: "Overdue by 2 days", progress: 1, overdue: true)
    drawText("Habits", in: CGRect(x: rect.minX, y: rect.minY + 846, width: rect.width, height: 46), size: 34, weight: .semibold)
    drawHabitCard(CGRect(x: rect.minX, y: rect.minY + 906, width: rect.width, height: 140), title: "Read 30 mins", subtitle: "Mindfulness", streak: "12", build: true)
    drawHabitCard(CGRect(x: rect.minX, y: rect.minY + 1070, width: rect.width, height: 140), title: "No late snacks", subtitle: "Break habit", streak: "8", build: false)
}

func renderActionDetail(_ rect: CGRect) {
    drawText("Morning Run", in: CGRect(x: rect.minX, y: rect.minY + 100, width: rect.width, height: 80), size: 58, weight: .bold)
    drawText("24 days strong", in: CGRect(x: rect.minX, y: rect.minY + 198, width: rect.width, height: 52), size: 36, weight: .medium, color: Theme.green)
    fillRounded(CGRect(x: rect.minX, y: rect.minY + 320, width: rect.width, height: 155), radius: 26, color: Theme.white)
    strokeRounded(CGRect(x: rect.minX, y: rect.minY + 320, width: rect.width, height: 155), radius: 26, color: Theme.border)
    drawText("Last done", in: CGRect(x: rect.minX + 38, y: rect.minY + 356, width: 260, height: 34), size: 24, color: Theme.muted)
    drawText("Yesterday", in: CGRect(x: rect.minX + 38, y: rect.minY + 395, width: 270, height: 48), size: 36, weight: .semibold)
    drawText("Goal", in: CGRect(x: rect.maxX - 245, y: rect.minY + 356, width: 190, height: 34), size: 24, color: Theme.muted, alignment: .right)
    drawText("30 days", in: CGRect(x: rect.maxX - 245, y: rect.minY + 395, width: 190, height: 48), size: 36, weight: .semibold, alignment: .right)
    drawText("Consistency rhythm", in: CGRect(x: rect.minX, y: rect.minY + 560, width: rect.width, height: 48), size: 36, weight: .semibold)
    fillRounded(CGRect(x: rect.minX, y: rect.minY + 640, width: rect.width, height: 430), radius: 26, color: Theme.white)
    strokeRounded(CGRect(x: rect.minX, y: rect.minY + 640, width: rect.width, height: 430), radius: 26, color: Theme.border)
    let labels = ["M", "T", "W", "T", "F", "S", "S"]
    for (i, day) in labels.enumerated() {
        drawText(day, in: CGRect(x: rect.minX + 70 + CGFloat(i) * 88, y: rect.minY + 700, width: 48, height: 28), size: 18, color: Theme.muted, alignment: .center)
    }
    for row in 0..<4 {
        for col in 0..<7 {
            let active = !(row == 0 && [0, 3].contains(col)) && !(row == 3 && col > 3)
            let color = active ? Theme.green : Theme.border.withAlphaComponent(0.55)
            fillRounded(CGRect(x: rect.minX + 64 + CGFloat(col) * 88, y: rect.minY + 750 + CGFloat(row) * 74, width: 66, height: 56), radius: 4, color: color)
        }
    }
    fillRounded(CGRect(x: rect.minX, y: rect.maxY - 170, width: rect.width, height: 96), radius: 24, color: Theme.green)
    drawText("LOG TODAY", in: CGRect(x: rect.minX, y: rect.maxY - 137, width: rect.width, height: 32), size: 25, weight: .bold, color: Theme.white, alignment: .center)
}

func renderReminders(_ rect: CGRect) {
    drawText("Actions", in: CGRect(x: rect.minX, y: rect.minY + 100, width: rect.width, height: 68), size: 58, weight: .bold)
    drawText("Track hourly, daily, weekly, or whenever life happens.", in: CGRect(x: rect.minX, y: rect.minY + 178, width: rect.width, height: 78), size: 26, color: Theme.muted, lineHeight: 34)
    drawActionCard(CGRect(x: rect.minX, y: rect.minY + 325, width: rect.width, height: 270), title: "Drank Water", time: "1 hour ago", progress: 0.74)
    drawActionCard(CGRect(x: rect.minX, y: rect.minY + 630, width: rect.width, height: 270), title: "Changed Oil", time: "3 months ago", progress: 0.66)
    fillRounded(CGRect(x: rect.minX, y: rect.minY + 970, width: rect.width, height: 220), radius: 28, color: Theme.green)
    drawText("Smart reminders", in: CGRect(x: rect.minX + 42, y: rect.minY + 1018, width: rect.width - 84, height: 44), size: 34, weight: .semibold, color: Theme.white)
    drawText("If an action is overdue, HowLong nudges again on a gentle snooze rhythm.", in: CGRect(x: rect.minX + 42, y: rect.minY + 1078, width: rect.width - 84, height: 78), size: 25, color: Theme.white.withAlphaComponent(0.82), lineHeight: 34)
}

func renderHabits(_ rect: CGRect) {
    drawText("Habits", in: CGRect(x: rect.minX, y: rect.minY + 100, width: rect.width, height: 68), size: 58, weight: .bold)
    drawText("Build what matters. Break what holds you back.", in: CGRect(x: rect.minX, y: rect.minY + 178, width: rect.width, height: 78), size: 26, color: Theme.muted, lineHeight: 34)
    drawHabitCard(CGRect(x: rect.minX, y: rect.minY + 310, width: rect.width, height: 160), title: "Morning stretch", subtitle: "Build habit", streak: "18", build: true)
    drawHabitCard(CGRect(x: rect.minX, y: rect.minY + 505, width: rect.width, height: 160), title: "Read 30 mins", subtitle: "Build habit", streak: "12", build: true)
    drawHabitCard(CGRect(x: rect.minX, y: rect.minY + 700, width: rect.width, height: 160), title: "No smoking", subtitle: "Break habit", streak: "42", build: false)
    fillRounded(CGRect(x: rect.minX, y: rect.minY + 945, width: rect.width, height: 250), radius: 28, color: Theme.white)
    strokeRounded(CGRect(x: rect.minX, y: rect.minY + 945, width: rect.width, height: 250), radius: 28, color: Theme.border)
    drawText("Weekly rhythm", in: CGRect(x: rect.minX + 42, y: rect.minY + 990, width: rect.width - 84, height: 42), size: 30, weight: .semibold)
    drawText("82%", in: CGRect(x: rect.minX + 42, y: rect.minY + 1048, width: 250, height: 86), size: 78, weight: .bold, color: Theme.green)
    drawProgressBar(CGRect(x: rect.minX + 42, y: rect.minY + 1160, width: rect.width - 84, height: 14), progress: 0.82)
}

func renderDetailCards(_ rect: CGRect) {
    drawText("Action details", in: CGRect(x: rect.minX, y: rect.minY + 100, width: rect.width, height: 68), size: 54, weight: .bold)
    drawText("Every action gets a clear history and reminder summary.", in: CGRect(x: rect.minX, y: rect.minY + 178, width: rect.width, height: 78), size: 26, color: Theme.muted, lineHeight: 34)
    fillRounded(CGRect(x: rect.minX, y: rect.minY + 315, width: rect.width, height: 210), radius: 26, color: Theme.white)
    strokeRounded(CGRect(x: rect.minX, y: rect.minY + 315, width: rect.width, height: 210), radius: 26, color: Theme.border)
    drawText("Drank Water", in: CGRect(x: rect.minX + 42, y: rect.minY + 362, width: rect.width - 84, height: 50), size: 38, weight: .semibold)
    drawText("42 minutes ago", in: CGRect(x: rect.minX + 42, y: rect.minY + 422, width: rect.width - 84, height: 46), size: 32, color: Theme.green)
    fillRounded(CGRect(x: rect.minX, y: rect.minY + 580, width: rect.width, height: 170), radius: 26, color: Theme.white)
    strokeRounded(CGRect(x: rect.minX, y: rect.minY + 580, width: rect.width, height: 170), radius: 26, color: Theme.border)
    drawText("Reminder", in: CGRect(x: rect.minX + 42, y: rect.minY + 625, width: 240, height: 38), size: 26, color: Theme.muted)
    drawText("Every 1 hour", in: CGRect(x: rect.minX + 42, y: rect.minY + 667, width: 340, height: 46), size: 35, weight: .semibold)
    fillRounded(CGRect(x: rect.minX, y: rect.minY + 800, width: rect.width, height: 170), radius: 26, color: Theme.white)
    strokeRounded(CGRect(x: rect.minX, y: rect.minY + 800, width: rect.width, height: 170), radius: 26, color: Theme.border)
    drawText("Category", in: CGRect(x: rect.minX + 42, y: rect.minY + 845, width: 240, height: 38), size: 26, color: Theme.muted)
    drawText("Health", in: CGRect(x: rect.minX + 42, y: rect.minY + 887, width: 340, height: 46), size: 35, weight: .semibold)
    fillRounded(CGRect(x: rect.minX, y: rect.maxY - 170, width: rect.width, height: 96), radius: 24, color: Theme.green)
    drawText("LOG NOW", in: CGRect(x: rect.minX, y: rect.maxY - 137, width: rect.width, height: 32), size: 25, weight: .bold, color: Theme.white, alignment: .center)
}

let features = [
    Feature(
        filename: "01-today-overview.png",
        eyebrow: "HowLong",
        title: "Know how long it’s been",
        subtitle: "See overdue actions and today’s habits in one calm view.",
        renderPhone: renderToday
    ),
    Feature(
        filename: "02-action-detail.png",
        eyebrow: "Actions",
        title: "Log recurring actions fast",
        subtitle: "Track water, car maintenance, plants, medication, and anything else that repeats.",
        renderPhone: renderReminders
    ),
    Feature(
        filename: "03-habit-tracking.png",
        eyebrow: "Habits",
        title: "Build streaks or break patterns",
        subtitle: "Separate habit types make progress easier to understand.",
        renderPhone: renderHabits
    ),
    Feature(
        filename: "04-consistency.png",
        eyebrow: "Rhythm",
        title: "See your consistency clearly",
        subtitle: "Detail screens show progress without clutter.",
        renderPhone: renderActionDetail
    ),
    Feature(
        filename: "05-details.png",
        eyebrow: "Details",
        title: "Every tracker has context",
        subtitle: "Open any action to review reminders, category, and logging history.",
        renderPhone: renderDetailCards
    )
]

func renderFeature(_ feature: Feature) throws {
    let image = NSImage(size: canvas)
    image.lockFocus()

    Theme.mint.setFill()
    CGRect(origin: .zero, size: canvas).fill()
    fillRounded(CGRect(x: -120, y: 1220, width: 1320, height: 900), radius: 140, color: Theme.mintStrong.withAlphaComponent(0.35))

    drawText(feature.eyebrow.uppercased(), in: CGRect(x: 88, y: 92, width: 904, height: 34), size: 24, weight: .bold, color: Theme.green, alignment: .center)
    drawText(feature.title, in: CGRect(x: 78, y: 150, width: 924, height: 190), size: 68, weight: .bold, alignment: .center, lineHeight: 78)
    drawText(feature.subtitle, in: CGRect(x: 126, y: 342, width: 828, height: 104), size: 31, color: Theme.muted, alignment: .center, lineHeight: 40)

    drawPhoneFrame(CGRect(x: 130, y: 515, width: 820, height: 1320), render: feature.renderPhone)

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "HowLongScreenshots", code: 1)
    }

    try png.write(to: outputDirectory.appendingPathComponent(feature.filename))
}

for feature in features {
    try renderFeature(feature)
}

print("Generated \(features.count) screenshots in \(outputDirectory.path)")
