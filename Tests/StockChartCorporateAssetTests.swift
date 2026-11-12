import AppKit
import Foundation

// Inspect decoded catalog assets as well as their luminosity bindings. These
// checks complement the on-device rendering test; they do not infer a real
// company's server colorType from public financial results.
@main
struct StockChartCorporateAssetTests {
    static func main() throws {
        precondition(CommandLine.arguments.count == 2, "Expected the repository path")
        let glyphs = URL(fileURLWithPath: CommandLine.arguments[1])
            .appendingPathComponent("SuperPreview/Assets.xcassets/Glyph")
        let assets = ["chart_mark_finance_red_up", "chart_mark_finance_green_up",
                      "chart_mark_finance_green_down", "chart_mark_finance_red_down",
                      "chart_mark_finance_gray", "chart_mark_dividen"]
        for asset in assets {
            let directory = glyphs.appendingPathComponent("\(asset).imageset")
            let data = try Data(contentsOf: directory.appendingPathComponent("Contents.json"))
            let catalog = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let images = catalog["images"] as! [[String: Any]]
            for scale in [2, 3] {
                var decoded: [String: NSBitmapImageRep] = [:]
                for appearance in ["light", "dark"] {
                    let filename = "\(asset)_\(appearance)@\(scale)x.png"
                    let matches = images.filter { item in
                        guard item["filename"] as? String == filename,
                              item["scale"] as? String == "\(scale)x" else { return false }
                        let appearances = item["appearances"] as? [[String: String]] ?? []
                        return appearance == "dark"
                            ? appearances.contains { $0["appearance"] == "luminosity" && $0["value"] == "dark" }
                            : appearances.isEmpty
                    }
                    precondition(matches.count == 1, "Incorrect catalog binding for \(filename)")
                    let png = try Data(contentsOf: directory.appendingPathComponent(filename))
                    guard let image = NSBitmapImageRep(data: png) else {
                        preconditionFailure("Could not decode \(filename)")
                    }
                    precondition(image.pixelsWide == 13 * scale && image.pixelsHigh == 13 * scale,
                                 "Unexpected size for \(filename)")
                    decoded[appearance] = image

                    if asset.contains("_red_") || asset.contains("_green_") {
                        let isRed = asset.contains("_red_")
                        func isMarkerColor(_ x: Int, _ y: Int) -> Bool {
                            let color = image.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
                            guard color.alphaComponent > 0.9 else { return false }
                            return isRed
                                ? color.redComponent > color.greenComponent + 0.2 && color.redComponent > color.blueComponent + 0.2
                                : color.greenComponent > color.redComponent + 0.2 && color.greenComponent > color.blueComponent + 0.06
                        }
                        let colored = (0..<image.pixelsHigh).reduce(0) { total, y in
                            total + (0..<image.pixelsWide).filter { isMarkerColor($0, y) }.count
                        }
                        precondition(colored > image.pixelsWide * image.pixelsHigh / 4,
                                     "Expected a \(isRed ? "red" : "green") marker in \(filename)")
                        func coloredPixels(inRow y: Int) -> Int {
                            (0..<image.pixelsWide).filter { isMarkerColor($0, y) }.count
                        }
                        let top = coloredPixels(inRow: scale)
                        let bottom = coloredPixels(inRow: image.pixelsHigh - scale - 1)
                        if asset.hasSuffix("_up") {
                            precondition(top + 5 < bottom, "Expected an upward point in \(filename)")
                        } else {
                            precondition(bottom + 5 < top, "Expected a downward point in \(filename)")
                        }
                    }
                }
                let light = decoded["light"]!, dark = decoded["dark"]!
                var changedPixels = 0
                for y in 0..<light.pixelsHigh {
                    for x in 0..<light.pixelsWide {
                        let a = light.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
                        let b = dark.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
                        let delta = abs(a.redComponent - b.redComponent) + abs(a.greenComponent - b.greenComponent)
                            + abs(a.blueComponent - b.blueComponent) + abs(a.alphaComponent - b.alphaComponent)
                        if delta > 0.1 { changedPixels += 1 }
                    }
                }
                precondition(changedPixels > light.pixelsWide * light.pixelsHigh / 10,
                             "Light/dark decoded pixels should differ for \(asset) @\(scale)x")
            }
        }
        print("StockChartCorporateAssetTests passed")
    }
}
