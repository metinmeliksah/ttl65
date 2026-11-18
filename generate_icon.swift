import AppKit

func renderIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: CGSize(width: size, height: size))
    img.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    let path = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.05, dy: size * 0.05),
                            xRadius: cornerRadius,
                            yRadius: cornerRadius)

    // Gradient background: Electric Blue to Indigo
    let gradient = NSGradient(
        starting: NSColor(red: 0.12, green: 0.53, blue: 0.98, alpha: 1.0),
        ending: NSColor(red: 0.08, green: 0.22, blue: 0.72, alpha: 1.0)
    )
    gradient?.draw(in: path, angle: -45)

    // Glowing border
    NSColor(white: 1.0, alpha: 0.2).setStroke()
    path.lineWidth = size * 0.02
    path.stroke()

    // Top Label: "TTL"
    let ttlText = "TTL" as NSString
    let ttlFont = NSFont.systemFont(ofSize: size * 0.14, weight: .heavy)
    let ttlAttrs: [NSAttributedString.Key: Any] = [
        .font: ttlFont,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.85)
    ]
    let ttlSize = ttlText.size(withAttributes: ttlAttrs)
    let ttlRect = NSRect(
        x: (size - ttlSize.width) / 2,
        y: size * 0.65,
        width: ttlSize.width,
        height: ttlSize.height
    )
    ttlText.draw(in: ttlRect, withAttributes: ttlAttrs)

    // Main Number: "65"
    let numberText = "65" as NSString
    let numberFont = NSFont.systemFont(ofSize: size * 0.45, weight: .black)
    let numberAttrs: [NSAttributedString.Key: Any] = [
        .font: numberFont,
        .foregroundColor: NSColor.white
    ]
    let numSize = numberText.size(withAttributes: numberAttrs)
    let numRect = NSRect(
        x: (size - numSize.width) / 2,
        y: size * 0.18,
        width: numSize.width,
        height: numSize.height
    )
    numberText.draw(in: numRect, withAttributes: numberAttrs)

    img.unlockFocus()
    return img
}

func savePNG(image: NSImage, path: String, targetSize: Int) {
    guard let tiffData = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiffData),
          let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG for \(targetSize)")
        return
    }
    try? pngData.write(to: URL(fileURLWithPath: path))
}

let fm = FileManager.default
let iconsetPath = "/tmp/AppIcon.iconset"
try? fm.removeItem(atPath: iconsetPath)
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for (sz, filename) in sizes {
    let img = renderIcon(size: CGFloat(sz))
    savePNG(image: img, path: "\(iconsetPath)/\(filename)", targetSize: sz)
}

print("Iconset created successfully at \(iconsetPath)")
