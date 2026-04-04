#!/usr/bin/env swift
import AppKit

// Generate ClaudeBuddy app icon from emoji
let iconsetDir = "Resources/AppIcon.iconset"
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024)
]

for (name, size) in sizes {
    let s = CGFloat(size)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()

    // Background: rounded rect with gradient
    let bgRect = NSRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.22
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Dark purple gradient background
    let gradient = NSGradient(colors: [
        NSColor(red: 0.15, green: 0.10, blue: 0.25, alpha: 1.0),
        NSColor(red: 0.08, green: 0.05, blue: 0.18, alpha: 1.0)
    ])!
    gradient.draw(in: bgPath, angle: -90)

    // Subtle border
    NSColor(white: 0.3, alpha: 0.5).setStroke()
    bgPath.lineWidth = s * 0.02
    bgPath.stroke()

    // Draw emoji centered
    let emoji = "🐾"
    let fontSize = s * 0.55
    let font = NSFont.systemFont(ofSize: fontSize)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font
    ]
    let attrStr = NSAttributedString(string: emoji, attributes: attrs)
    let textSize = attrStr.size()
    let textX = (s - textSize.width) / 2
    let textY = (s - textSize.height) / 2 - s * 0.02
    attrStr.draw(at: NSPoint(x: textX, y: textY))

    // Small "CB" text at bottom
    if size >= 64 {
        let labelSize = s * 0.12
        let labelFont = NSFont.systemFont(ofSize: labelSize, weight: .bold)
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: NSColor(white: 0.7, alpha: 0.8)
        ]
        let label = NSAttributedString(string: "buddy", attributes: labelAttrs)
        let labelW = label.size().width
        label.draw(at: NSPoint(x: (s - labelW) / 2, y: s * 0.08))
    }

    img.unlockFocus()

    // Save as PNG
    guard let tiff = img.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create \(name)")
        continue
    }
    let path = "\(iconsetDir)/\(name).png"
    try! png.write(to: URL(fileURLWithPath: path))
    print("Created \(path) (\(size)x\(size))")
}

print("Done! Now run: iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns")
