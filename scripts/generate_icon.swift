import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// Enable high quality antialiasing
ctx.setAllowsAntialiasing(true)
ctx.setShouldAntialias(true)

// Squircle frame (standard macOS icon frame: 824x824 centered in 1024x1024)
let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185
let squirclePath = NSBezierPath(roundedRect: squircleRect, xRadius: cornerRadius, yRadius: cornerRadius)

// Shadow for squircle
let shadow = NSShadow()
shadow.shadowBlurRadius = 32
shadow.shadowOffset = NSSize(width: 0, height: -14)
shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)

ctx.saveGState()
shadow.set()
NSColor.black.withAlphaComponent(0.01).setFill()
squirclePath.fill()
ctx.restoreGState()

// Clip to squircle
ctx.saveGState()
squirclePath.addClip()

// Background Gradient: Deep Twilight Midnight
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bgColors = [
    NSColor(calibratedRed: 0.08, green: 0.12, blue: 0.22, alpha: 1.0).cgColor, // Top deep midnight
    NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.10, alpha: 1.0).cgColor  // Bottom near-black
] as CFArray
let bgLocations: [CGFloat] = [0.0, 1.0]
if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
}

// Subtle celestial ambient backlight (soft radial glow in upper right)
let glowColors = [
    NSColor(calibratedRed: 0.25, green: 0.35, blue: 0.60, alpha: 0.35).cgColor,
    NSColor(calibratedRed: 0.08, green: 0.12, blue: 0.22, alpha: 0.0).cgColor
] as CFArray
if let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(glowGrad, startCenter: CGPoint(x: 540, y: 550), startRadius: 20, endCenter: CGPoint(x: 540, y: 550), endRadius: 360, options: [])
}

// Draw Crescent Moon
ctx.saveGState()

// Outer circle: Center (490, 512), radius 200
let outerCenter = CGPoint(x: 490, y: 512)
let outerRadius: CGFloat = 200
let innerCenter = CGPoint(x: 565, y: 550)
let innerRadius: CGFloat = 175

let moonPath = CGMutablePath()
moonPath.addArc(center: outerCenter, radius: outerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)

// Subtract inner circle using Even-Odd or clipping
let cutoutPath = CGMutablePath()
cutoutPath.addArc(center: innerCenter, radius: innerRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)

// Combined crescent path:
let crescentCGPath = CGMutablePath()
crescentCGPath.addPath(moonPath)
crescentCGPath.addPath(cutoutPath)

ctx.addPath(crescentCGPath)
ctx.clip(using: .evenOdd)

// Fill Crescent with Warm Champagne Gold Gradient
let goldColors = [
    NSColor(calibratedRed: 1.00, green: 0.90, blue: 0.60, alpha: 1.0).cgColor, // Top light gold
    NSColor(calibratedRed: 0.90, green: 0.68, blue: 0.35, alpha: 1.0).cgColor  // Bottom warm amber gold
] as CFArray
if let goldGrad = CGGradient(colorsSpace: colorSpace, colors: goldColors, locations: [0.0, 1.0]) {
    ctx.drawLinearGradient(goldGrad, start: CGPoint(x: 450, y: 720), end: CGPoint(x: 520, y: 320), options: [])
}
ctx.restoreGState()

// Draw 8-pointed star in upper right of crescent: Center (620, 600)
func drawStar(center: CGPoint, points: Int, innerRadius: CGFloat, outerRadius: CGFloat) {
    let path = CGMutablePath()
    let step = .pi / CGFloat(points)
    for i in 0..<(points * 2) {
        let r = (i % 2 == 0) ? outerRadius : innerRadius
        let angle = CGFloat(i) * step - .pi / 2
        let pt = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
    }
    path.closeSubpath()
    
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    if let starGrad = CGGradient(colorsSpace: colorSpace, colors: goldColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(starGrad, start: CGPoint(x: center.x, y: center.y + outerRadius), end: CGPoint(x: center.x, y: center.y - outerRadius), options: [])
    }
    ctx.restoreGState()
}

drawStar(center: CGPoint(x: 620, y: 600), points: 8, innerRadius: 26, outerRadius: 62)

// Subtle dome arch silhouette at the bottom (timeless architectural nod)
let domePath = CGMutablePath()
domePath.move(to: CGPoint(x: 320, y: 100))
domePath.addLine(to: CGPoint(x: 320, y: 220))
domePath.addQuadCurve(to: CGPoint(x: 512, y: 330), control: CGPoint(x: 320, y: 330))
domePath.addQuadCurve(to: CGPoint(x: 704, y: 220), control: CGPoint(x: 704, y: 330))
domePath.addLine(to: CGPoint(x: 704, y: 100))
domePath.closeSubpath()

ctx.saveGState()
ctx.addPath(domePath)
ctx.setFillColor(NSColor(calibratedRed: 0.12, green: 0.18, blue: 0.32, alpha: 0.35).cgColor)
ctx.fillPath()
ctx.restoreGState()

// Subtle inner border stroke for glass/card effect
squirclePath.lineWidth = 2
NSColor.white.withAlphaComponent(0.12).setStroke()
squirclePath.stroke()

ctx.restoreGState() // End squircle clip

image.unlockFocus()

// Save to 1024x1024 PNG
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    exit(1)
}
try png.write(to: URL(fileURLWithPath: "/tmp/icon_1024.png"))
print("Generated 1024x1024 icon successfully!")
