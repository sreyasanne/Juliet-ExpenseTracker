import Foundation
import SwiftData

@Model
final class CustomTag {
    var id: UUID
    var name: String
    var colorHex: String   // e.g. "FF6B6B"
    var icon: String       // SF Symbol name

    init(name: String, colorHex: String = "5E5CE6", icon: String = "tag.fill") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
    }
}
