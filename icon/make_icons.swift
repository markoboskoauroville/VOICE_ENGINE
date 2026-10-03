// The two apps' icons, drawn (MANTRA_MANIFEST swift-apps.md: every app gets its own icon, showing what it does).
//   subtitle.png  Claude to Marko voice (Mantra): the subtitle band, orange words, the word being said in red
//   answer.png    Answer Claude (Mantra): a reply bubble with a text cursor in it
import AppKit
func draw(_ name: String, _ body: (CGContext, CGRect) -> Void) {
    let S: CGFloat = 1024
    let img = NSImage(size: NSSize(width: S, height: S)); img.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    ctx.addPath(CGPath(roundedRect: tile, cornerWidth: 180, cornerHeight: 180, transform: nil))
    ctx.setFillColor(NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.06, alpha: 1).cgColor); ctx.fillPath()
    body(ctx, tile)
    img.unlockFocus()
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: name))
}
let orange = NSColor(calibratedRed: 0.91, green: 0.64, blue: 0.24, alpha: 1)
let red = NSColor(calibratedRed: 1, green: 0.23, blue: 0.19, alpha: 1)
draw("subtitle.png") { ctx, t in
    let band = CGRect(x: t.minX, y: t.midY - 120, width: t.width, height: 240)
    ctx.saveGState(); ctx.addPath(CGPath(roundedRect: t, cornerWidth: 180, cornerHeight: 180, transform: nil)); ctx.clip()
    NSColor(white: 0.3, alpha: 1).setFill(); NSBezierPath(rect: band).fill(); ctx.restoreGState()
    let f = NSFont(name: "Helvetica Neue", size: 118)!
    let s = NSMutableAttributedString(string: "I hear you", attributes: [.font: f, .foregroundColor: orange])
    s.addAttribute(.foregroundColor, value: red, range: NSRange(location: 2, length: 4))
    let sz = s.size(); s.draw(at: NSPoint(x: t.midX - sz.width / 2, y: t.midY - sz.height / 2))
}
draw("answer.png") { ctx, t in
    let b = CGRect(x: t.minX + 120, y: t.minY + 230, width: t.width - 240, height: 420)
    let p = CGMutablePath(); p.addRoundedRect(in: b, cornerWidth: 90, cornerHeight: 90)
    p.move(to: CGPoint(x: b.minX + 140, y: b.minY + 2)); p.addLine(to: CGPoint(x: b.minX + 110, y: b.minY - 110)); p.addLine(to: CGPoint(x: b.minX + 250, y: b.minY + 2))
    ctx.addPath(p); ctx.setFillColor(NSColor(white: 0.16, alpha: 1).cgColor); ctx.fillPath()
    let f = NSFont(name: "Helvetica Neue", size: 120)!
    let s = NSAttributedString(string: "yes", attributes: [.font: f, .foregroundColor: NSColor(calibratedRed: 0.95, green: 0.87, blue: 0.71, alpha: 1)])
    let sz = s.size(); let x = b.minX + 110; s.draw(at: NSPoint(x: x, y: b.midY - sz.height / 2))
    orange.setFill(); NSBezierPath(rect: CGRect(x: x + sz.width + 22, y: b.midY - 75, width: 16, height: 150)).fill()
}
print("ok")
