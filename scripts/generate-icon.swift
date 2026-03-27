#!/usr/bin/env swift

import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let s = size

// ===== BACKGROUND =====
let inset = s * 0.01
let bgRect = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: s * 0.22, yRadius: s * 0.22)

// Blue → Indigo gradient
let mainGrad = NSGradient(colorsAndLocations:
    (NSColor(calibratedHue: 0.60, saturation: 0.82, brightness: 0.98, alpha: 1.0), 0.0),
    (NSColor(calibratedHue: 0.73, saturation: 0.78, brightness: 0.78, alpha: 1.0), 1.0)
)!
mainGrad.draw(in: bgPath, angle: -50)

// Subtle depth overlay
let depthGrad = NSGradient(colorsAndLocations:
    (NSColor(white: 1.0, alpha: 0.10), 0.0),
    (NSColor(white: 0.0, alpha: 0.06), 1.0)
)!
depthGrad.draw(in: bgPath, angle: -90)

// ===== GLOBE =====
let cx = s * 0.50
let cy = s * 0.50
let r  = s * 0.31

let thick: CGFloat = s * 0.024
let thin:  CGFloat = s * 0.014

let bright = NSColor(white: 1.0, alpha: 0.90)
let medium = NSColor(white: 1.0, alpha: 0.60)
let faint  = NSColor(white: 1.0, alpha: 0.35)

// Clip interior elements to globe circle
NSGraphicsContext.current?.saveGraphicsState()
let clipPath = NSBezierPath(ovalIn: NSRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
clipPath.setClip()

// Latitude lines
for frac in [-0.66, -0.33, 0.33, 0.66] as [CGFloat] {
    let ly = cy + r * frac
    let hw = sqrt(max(0, r * r - pow(r * frac, 2)))
    let line = NSBezierPath()
    line.move(to: NSPoint(x: cx - hw, y: ly))
    line.line(to: NSPoint(x: cx + hw, y: ly))
    line.lineWidth = thin
    faint.setStroke()
    line.stroke()
}

// Equator
let eq = NSBezierPath()
eq.move(to: NSPoint(x: cx - r, y: cy))
eq.line(to: NSPoint(x: cx + r, y: cy))
eq.lineWidth = thin
medium.setStroke()
eq.stroke()

// Meridian ellipses
for w in [0.55, 0.25] as [CGFloat] {
    let ew = r * 2 * w
    let ellipse = NSBezierPath(ovalIn: NSRect(x: cx - ew / 2, y: cy - r, width: ew, height: 2 * r))
    ellipse.lineWidth = thin
    faint.setStroke()
    ellipse.stroke()
}

// Prime meridian (vertical)
let pm = NSBezierPath()
pm.move(to: NSPoint(x: cx, y: cy - r))
pm.line(to: NSPoint(x: cx, y: cy + r))
pm.lineWidth = thin
medium.setStroke()
pm.stroke()

NSGraphicsContext.current?.restoreGraphicsState()

// Outer circle (crisp, outside clip)
let outer = NSBezierPath(ovalIn: NSRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
outer.lineWidth = thick
bright.setStroke()
outer.stroke()

// ===== "A" OVERLAY =====
// Bold "A" centered on the globe — represents language/text input
let aFont = NSFont.systemFont(ofSize: s * 0.30, weight: .bold)
let aAttrs: [NSAttributedString.Key: Any] = [
    .font: aFont,
    .foregroundColor: NSColor(white: 1.0, alpha: 0.92),
]
let aStr = "A" as NSString
let aSize = aStr.size(withAttributes: aAttrs)
aStr.draw(at: NSPoint(x: cx - aSize.width / 2, y: cy - aSize.height / 2), withAttributes: aAttrs)

// ===== SWITCH ARROWS (bottom-right badge) =====
let badgeCx = s * 0.76
let badgeCy = s * 0.24
let badgeR  = s * 0.11

// Green circle badge
let badge = NSBezierPath(ovalIn: NSRect(
    x: badgeCx - badgeR, y: badgeCy - badgeR,
    width: 2 * badgeR, height: 2 * badgeR
))
NSColor(calibratedHue: 0.38, saturation: 0.72, brightness: 0.82, alpha: 1.0).setFill()
badge.fill()
NSColor(white: 1.0, alpha: 0.25).setStroke()
badge.lineWidth = s * 0.006
badge.stroke()

// Draw two arrows (⇌) manually for crisp rendering
let arrowColor = NSColor.white
arrowColor.setStroke()
arrowColor.setFill()

let aw: CGFloat = badgeR * 0.65  // arrow half-width
let ah: CGFloat = badgeR * 0.22  // arrow head size
let gap: CGFloat = badgeR * 0.18 // vertical gap between arrows
let lw: CGFloat = s * 0.016

// Top arrow (pointing right)
let topY = badgeCy + gap
let rightArrow = NSBezierPath()
rightArrow.move(to: NSPoint(x: badgeCx - aw, y: topY))
rightArrow.line(to: NSPoint(x: badgeCx + aw, y: topY))
rightArrow.lineWidth = lw
rightArrow.lineCapStyle = .round
rightArrow.stroke()
// Arrowhead
let rHead = NSBezierPath()
rHead.move(to: NSPoint(x: badgeCx + aw - ah, y: topY + ah))
rHead.line(to: NSPoint(x: badgeCx + aw, y: topY))
rHead.line(to: NSPoint(x: badgeCx + aw - ah, y: topY - ah))
rHead.lineWidth = lw
rHead.lineCapStyle = .round
rHead.lineJoinStyle = .round
rHead.stroke()

// Bottom arrow (pointing left)
let botY = badgeCy - gap
let leftArrow = NSBezierPath()
leftArrow.move(to: NSPoint(x: badgeCx + aw, y: botY))
leftArrow.line(to: NSPoint(x: badgeCx - aw, y: botY))
leftArrow.lineWidth = lw
leftArrow.lineCapStyle = .round
leftArrow.stroke()
// Arrowhead
let lHead = NSBezierPath()
lHead.move(to: NSPoint(x: badgeCx - aw + ah, y: botY + ah))
lHead.line(to: NSPoint(x: badgeCx - aw, y: botY))
lHead.line(to: NSPoint(x: badgeCx - aw + ah, y: botY - ah))
lHead.lineWidth = lw
lHead.lineCapStyle = .round
lHead.lineJoinStyle = .round
lHead.stroke()

image.unlockFocus()

// ===== EXPORT =====
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to generate PNG\n", stderr)
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Generated: \(outputPath)")
