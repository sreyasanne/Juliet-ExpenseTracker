import SwiftUI

extension Color {
    /// Initialize a Color from a hex string like "FF6B6B" or "#FF6B6B"
    init(hex: String) {
        var clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        clean = clean.hasPrefix("#") ? String(clean.dropFirst()) : clean

        var rgb: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >>  8) & 0xFF) / 255
        let b = Double( rgb        & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
