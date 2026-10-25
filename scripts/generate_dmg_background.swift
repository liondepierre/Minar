import AppKit

let width: CGFloat = 660
let height: CGFloat = 400
let scale: CGFloat = 2.0 // Retina 2x

let size = NSSize(width: width * scale, height: height * scale)
let image = NSImage(size: size)

image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

ctx.scaleBy(x: scale, y: scale)
ctx.setAllowsAntialiasing(true)
ctx.setShouldAntialias(true)

let colorSpace = CGColorSpaceCreateDeviceRGB()

// 1. Midnight Dark Background Gradient
let bgColors = [
    NSColor(calibratedRed: 0.07, green: 0.11, blue: 0.20, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.10, alpha: 1.0).cgColor
] as CFArray
if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: width / 2, y: height), end: CGPoint(x: width / 2, y: 0), options: [])
}

// 2. Subtle Radial Glow in Center Top
let glowColors = [
    NSColor(calibratedRed: 0.25, green: 0.38, blue: 0.65, alpha: 0.25).cgColor,
    NSColor(calibratedRed: 0.07, green: 0.11, blue: 0.20, alpha: 0.0).cgColor
] as CFArray
if let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(glowGrad, startCenter: CGPoint(x: width / 2, y: height * 0.75), startRadius: 0, endCenter: CGPoint(x: width / 2, y: height * 0.75), endRadius: 280, options: [.drawsAfterEndLocation])
}

// 3. Subtle Arch / Mihrab outline watermark behind icons
let archPath = CGMutablePath()
let archRect = CGRect(x: width / 2 - 140, y: 70, width: 280, height: 240)
archPath.addRoundedRect(in: archRect, cornerWidth: 140, cornerHeight: 140)
ctx.saveGState()
ctx.setLineWidth(1.0)
ctx.setStrokeColor(NSColor(calibratedRed: 0.85, green: 0.75, blue: 0.45, alpha: 0.08).cgColor)
ctx.addPath(archPath)
ctx.strokePath()
ctx.restoreGState()

// 4. Central Arrow between App and Applications folder
let arrowCenter = CGPoint(x: width / 2, y: 195)
let arrowFont = NSFont.systemFont(ofSize: 32, weight: .light)
let arrowAttrs: [NSAttributedString.Key: Any] = [
    .font: arrowFont,
    .foregroundColor: NSColor(calibratedRed: 0.92, green: 0.78, blue: 0.42, alpha: 0.65)
]
let arrowStr = NSAttributedString(string: "➔", attributes: arrowAttrs)
let arrowSize = arrowStr.size()
arrowStr.draw(at: CGPoint(x: arrowCenter.x - arrowSize.width / 2, y: arrowCenter.y - arrowSize.height / 2))

// 5. Header: "Minar" Title
let titleFont = NSFont.systemFont(ofSize: 28, weight: .bold)
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: titleFont,
    .foregroundColor: NSColor(calibratedRed: 0.96, green: 0.94, blue: 0.90, alpha: 0.95)
]
let titleStr = NSAttributedString(string: "Minar", attributes: titleAttrs)
let titleSize = titleStr.size()
titleStr.draw(at: CGPoint(x: width / 2 - titleSize.width / 2, y: height - 60))

// 6. Subtitle: "Drag to Applications to install"
let subFont = NSFont.systemFont(ofSize: 13, weight: .medium)
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: subFont,
    .foregroundColor: NSColor(calibratedRed: 0.65, green: 0.72, blue: 0.85, alpha: 0.75)
]
let subStr = NSAttributedString(string: "Drag to Applications to install", attributes: subAttrs)
let subSize = subStr.size()
subStr.draw(at: CGPoint(x: width / 2 - subSize.width / 2, y: height - 85))

// 7. Icon placeholder label hints
let labelFont = NSFont.systemFont(ofSize: 11, weight: .medium)
let labelAttrs: [NSAttributedString.Key: Any] = [
    .font: labelFont,
    .foregroundColor: NSColor(calibratedRed: 0.55, green: 0.62, blue: 0.75, alpha: 0.50)
]
let appHint = NSAttributedString(string: "Drop into Applications", attributes: labelAttrs)
let appHintSize = appHint.size()
appHint.draw(at: CGPoint(x: width / 2 - appHintSize.width / 2, y: 95))

// 8. Outer thin glass border
let borderRect = CGRect(x: 1, y: 1, width: width - 2, height: height - 2)
let borderPath = NSBezierPath(rect: borderRect)
borderPath.lineWidth = 1
NSColor(calibratedWhite: 1.0, alpha: 0.1).setStroke()
borderPath.stroke()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    exit(1)
}

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/dmg_background.png"
try png.write(to: URL(fileURLWithPath: outPath))
print("Generated DMG background at \(outPath)")
