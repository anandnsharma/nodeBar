import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct NodeBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var manager = AppManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(manager: manager)
                .onAppear {
                    manager.autoStartApps()
                }
        } label: {
            MenuBarIcon(runningCount: manager.runningCount)
        }
        .menuBarExtraStyle(.window)
        .defaultSize(width: 320, height: 400)
    }
}

/// Renders the menu bar icon with an optional running-app count badge.
struct MenuBarIcon: View {
    let runningCount: Int

    var body: some View {
        Image(nsImage: renderIcon())
    }

    private func renderIcon() -> NSImage {
        let iconSize = NSSize(width: 18, height: 18)
        let image = NSImage(size: iconSize, flipped: false) { rect in
            // Draw squircle with "nB" engraved
            let iconRect = NSRect(x: 0, y: (rect.height - 16) / 2, width: 16, height: 16)
            Self.drawIcon(in: iconRect)

            // Draw badge if there are running apps
            if self.runningCount > 0 {
                let badgeText = "\(self.runningCount)"
                let font = NSFont.systemFont(ofSize: 8, weight: .bold)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.white,
                ]
                let textSize = (badgeText as NSString).size(withAttributes: attrs)

                let badgeWidth = max(textSize.width + 4, 10)
                let badgeHeight: CGFloat = 10
                let badgeX = rect.width - badgeWidth
                let badgeY = rect.height - badgeHeight

                let badgeRect = NSRect(x: badgeX, y: badgeY, width: badgeWidth, height: badgeHeight)

                // Badge background
                let path = NSBezierPath(roundedRect: badgeRect, xRadius: badgeHeight / 2, yRadius: badgeHeight / 2)
                NSColor.systemOrange.setFill()
                path.fill()

                // Badge text
                let textX = badgeX + (badgeWidth - textSize.width) / 2
                let textY = badgeY + (badgeHeight - textSize.height) / 2
                (badgeText as NSString).draw(at: NSPoint(x: textX, y: textY), withAttributes: attrs)
            }

            return true
        }
        image.isTemplate = runningCount == 0
        return image
    }

    /// Draws a squircle with "nB" cut out as transparent (template-compatible).
    private static func drawIcon(in rect: NSRect) {
        // Squircle (superellipse) background
        let bgPath = superellipsePath(in: rect, n: 4)
        NSColor.black.setFill()
        bgPath.fill()

        // Subtle border for definition
        let strokePath = superellipsePath(in: rect.insetBy(dx: 0.375, dy: 0.375), n: 4)
        strokePath.lineWidth = 0.75
        NSColor.black.withAlphaComponent(0.3).setStroke()
        strokePath.stroke()

        // Cut out "nB" text by erasing pixels to transparent
        let fontSize: CGFloat = rect.height * 0.65
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .heavy)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
        ]
        let text = "nB"
        let textSize = (text as NSString).size(withAttributes: attrs)
        let textX = rect.midX - textSize.width / 2
        let textY = rect.midY - textSize.height / 2

        NSGraphicsContext.current?.cgContext.setBlendMode(.clear)
        (text as NSString).draw(at: NSPoint(x: textX, y: textY), withAttributes: attrs)
        NSGraphicsContext.current?.cgContext.setBlendMode(.normal)
    }

    /// Returns a superellipse (squircle) bezier path: |x|^n + |y|^n = 1.
    private static func superellipsePath(in rect: NSRect, n: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        let cx = rect.midX
        let cy = rect.midY
        let a = rect.width / 2
        let b = rect.height / 2
        let exp = 2.0 / n
        let steps = 100

        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
            let cosT = cos(t)
            let sinT = sin(t)
            let x = cx + a * copysign(pow(abs(cosT), exp), cosT)
            let y = cy + b * copysign(pow(abs(sinT), exp), sinT)
            if i == 0 {
                path.move(to: NSPoint(x: x, y: y))
            } else {
                path.line(to: NSPoint(x: x, y: y))
            }
        }
        path.close()
        return path
    }
}

