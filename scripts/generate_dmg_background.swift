import AppKit

let width: CGFloat = 540
let height: CGFloat = 340
let scale: CGFloat = 2.0 // Retina 2x

let size = NSSize(width: width * scale, height: height * scale)
let image = NSImage(size: size)

image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

ctx.scaleBy(x: scale, y: scale)
ctx.setAllowsAntialiasing(true)
ctx.setShouldAntialias(true)

let colorSpace = CGColorSpaceCreateDeviceRGB()

// 1. Rich Navy Dark Blue Background Gradient
let bgColors = [
    NSColor(srgbRed: 0.05, green: 0.12, blue: 0.25, alpha: 1.0).cgColor, // Rich Navy
    NSColor(srgbRed: 0.02, green: 0.06, blue: 0.14, alpha: 1.0).cgColor  // Deep Navy base
] as CFArray
if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: width / 2, y: height), end: CGPoint(x: width / 2, y: 0), options: [])
}

// 2. Ambient Navy Radial Glow in upper center
let glowColors = [
    NSColor(srgbRed: 0.12, green: 0.24, blue: 0.48, alpha: 0.40).cgColor,
    NSColor(srgbRed: 0.05, green: 0.12, blue: 0.25, alpha: 0.0).cgColor
] as CFArray
if let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(glowGrad, startCenter: CGPoint(x: width / 2, y: height * 0.65), startRadius: 0, endCenter: CGPoint(x: width / 2, y: height * 0.65), endRadius: 220, options: [.drawsAfterEndLocation])
}

// 3. Subtle Arch contour (Minar theme)
let archPath = CGMutablePath()
let archRect = CGRect(x: width / 2 - 100, y: 60, width: 200, height: 180)
archPath.addRoundedRect(in: archRect, cornerWidth: 100, cornerHeight: 100)
ctx.saveGState()
ctx.setLineWidth(1.0)
ctx.setStrokeColor(NSColor(srgbRed: 0.85, green: 0.72, blue: 0.40, alpha: 0.12).cgColor)
ctx.addPath(archPath)
ctx.strokePath()
ctx.restoreGState()

// 4. Central Arrow between App and Applications folder
let arrowCenter = CGPoint(x: width / 2, y: 165)
let arrowFont = NSFont.systemFont(ofSize: 26, weight: .light)
let arrowAttrs: [NSAttributedString.Key: Any] = [
    .font: arrowFont,
    .foregroundColor: NSColor(srgbRed: 0.90, green: 0.76, blue: 0.40, alpha: 0.80)
]
let arrowStr = NSAttributedString(string: "➔", attributes: arrowAttrs)
let arrowSize = arrowStr.size()
arrowStr.draw(at: CGPoint(x: arrowCenter.x - arrowSize.width / 2, y: arrowCenter.y - arrowSize.height / 2))

// 5. Header: "Minar" Title
let titleFont = NSFont.systemFont(ofSize: 22, weight: .bold)
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: titleFont,
    .foregroundColor: NSColor(srgbRed: 0.95, green: 0.96, blue: 0.98, alpha: 0.95)
]
let titleStr = NSAttributedString(string: "Minar", attributes: titleAttrs)
let titleSize = titleStr.size()
titleStr.draw(at: CGPoint(x: width / 2 - titleSize.width / 2, y: height - 50))

// 6. Subtitle: "Drag to Applications to install"
let subFont = NSFont.systemFont(ofSize: 12, weight: .medium)
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: subFont,
    .foregroundColor: NSColor(srgbRed: 0.65, green: 0.75, blue: 0.90, alpha: 0.80)
]
let subStr = NSAttributedString(string: "Drag to Applications to install", attributes: subAttrs)
let subSize = subStr.size()
subStr.draw(at: CGPoint(x: width / 2 - subSize.width / 2, y: height - 72))

// 7. Outer subtle glass edge
let borderRect = CGRect(x: 1, y: 1, width: width - 2, height: height - 2)
let borderPath = NSBezierPath(rect: borderRect)
borderPath.lineWidth = 1
NSColor(calibratedWhite: 1.0, alpha: 0.12).setStroke()
borderPath.stroke()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    exit(1)
}

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/dmg_background.png"
try png.write(to: URL(fileURLWithPath: outPath))
print("Generated Navy Blue DMG background at \(outPath)")
