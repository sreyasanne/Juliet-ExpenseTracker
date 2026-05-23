import SwiftUI

// MARK: - AppTheme
// Strict four-color palette for Juliet.
// Every color used anywhere in the app must come from this file.
//
// Asset catalog names match Color("AppPrimary") etc. — see Assets.xcassets/

enum AppTheme {

    // ─── Core palette ────────────────────────────────────────────────────────

    /// Sky Blue #87CEEB — primary accent (buttons, icons, links, chart fill 1)
    static let primary    = Color("AppPrimary")

    /// Baby Pink #F4C2C2 — secondary accent (warnings, due states, chart fill 2)
    static let secondary  = Color("AppSecondary")

    /// #FFFFFF in light mode / #1A1A1A in dark mode — card & screen backgrounds
    static let background = Color("AppBackground")

    /// #1A1A1A in light mode / #FFFFFF in dark mode — all body text
    static let text       = Color("AppText")

    // ─── Opacity ramps (use instead of hardcoded .opacity) ───────────────────

    static let primaryXLight  = primary.opacity(0.08)
    static let primaryLight   = primary.opacity(0.18)
    static let primaryMedium  = primary.opacity(0.45)
    static let primaryStrong  = primary.opacity(0.75)

    static let secondaryXLight = secondary.opacity(0.08)
    static let secondaryLight  = secondary.opacity(0.18)
    static let secondaryMedium = secondary.opacity(0.45)
    static let secondaryStrong = secondary.opacity(0.75)

    static let textFaint      = text.opacity(0.35)
    static let textSubtle     = text.opacity(0.55)
    static let textSecondary  = text.opacity(0.70)

    // ─── Semantic roles ───────────────────────────────────────────────────────

    /// Use for interactive highlights, active tabs, filled buttons
    static let accent          = primary

    /// Use for "paid / done / confirmed" states
    static let success         = primary

    /// Use for "due / overdue / warning" states
    static let warning         = secondary

    /// Use for destructive actions (delete, error)
    static let destructive     = secondary

    // ─── Chart palette (alternating primary/secondary at varying opacities) ──
    // Index into this when you need N distinct chart series.

    static let chartPalette: [Color] = [
        primary,
        secondary,
        primary.opacity(0.55),
        secondary.opacity(0.55),
        primary.opacity(0.30),
        secondary.opacity(0.30),
        primaryStrong,
        secondaryStrong
    ]

    // ─── Tag-to-color assignment ──────────────────────────────────────────────

    /// Returns either AppTheme.primary or AppTheme.secondary for a tag name,
    /// alternating deterministically so every tag gets a distinct feel.
    static func colorForTag(_ tag: String) -> Color {
        let palette = Expense.predefinedTags
        if let idx = palette.firstIndex(of: tag) {
            return idx.isMultiple(of: 2) ? primary : secondary
        }
        // Custom tags — hash to one of the two accents
        return abs(tag.hashValue).isMultiple(of: 2) ? primary : secondary
    }

    // ─── Hex values (for models that store color as String) ──────────────────

    static let primaryHex   = "87CEEB"
    static let secondaryHex = "F4C2C2"
    static let backgroundHex = "FFFFFF"
    static let textHex      = "1A1A1A"
}
