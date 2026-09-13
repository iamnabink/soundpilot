// SoundPilotTests/DesignTokensDynamicResolutionTests.swift
// Verifies each dynamic DesignTokens.Colors token resolves to the expected
// NSColor for both `.aqua` (light) and `.darkAqua` (dark) appearances.
//
// This test catches three regressions:
//  1. A token's light or dark RGBA being changed inadvertently.
//  2. Two tokens accidentally sharing an NSColor.Name, which silently
//     merges them under NSColor's name cache.
//  3. The dynamicColor helper resolving the wrong branch for an appearance.
//
// Expectations are written as literal `0xRRGGBB` brand hexes via this file's
// own `hex(_:_:)` helper rather than by reading `DesignTokens.Brand`. Sourcing
// them from the app would make regression (1) untestable: editing a palette
// value would move the token and its expectation together.

import Testing
import SwiftUI
import AppKit
@testable import SoundPilot

@Suite("DesignTokens — Dynamic color resolution")
@MainActor
struct DesignTokensDynamicResolutionTests {

    // MARK: Helpers

    /// The SoundPilot brand palette, restated independently of the app.
    private enum Palette {
        static let primary: UInt32       = 0x1355D9
        static let background: UInt32    = 0x06194D
        static let accent: UInt32        = 0x19D9F5
        static let secondary: UInt32     = 0x8B35F5
        static let foreground: UInt32    = 0xD8E2F4
        static let primaryLight: UInt32  = 0x5A88E4
        static let accentDeep: UInt32    = 0x0D6C7A
        static let secondaryLight: UInt32 = 0xA868F8
        static let surfaceTint: UInt32   = 0xEDF2FA
        /// Light-appearance text/hairline color — same value as `background`.
        static let ink: UInt32           = background
    }

    /// Builds an sRGB NSColor from a `0xRRGGBB` literal plus alpha.
    private func hex(_ value: UInt32, _ alpha: CGFloat = 1.0) -> NSColor {
        NSColor(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    /// Resolves a SwiftUI Color (backed by an NSColor dynamic provider) to its
    /// concrete NSColor for the specified appearance, by entering that appearance
    /// as the drawing context.
    private func resolve(_ color: Color, appearance: NSAppearance) -> NSColor {
        var resolved: NSColor = .clear
        appearance.performAsCurrentDrawingAppearance {
            resolved = NSColor(color).usingColorSpace(.sRGB) ?? NSColor(color)
        }
        return resolved
    }

    /// Asserts a SwiftUI Color's resolved RGBA matches the expected NSColor's RGBA
    /// in the specified appearance, within a tolerance for floating-point drift.
    private func expectColor(
        _ token: Color,
        equals expected: NSColor,
        in appearance: NSAppearance,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let actual = resolve(token, appearance: appearance)
        let actualSRGB = actual.usingColorSpace(.sRGB) ?? actual
        let expectedSRGB = expected.usingColorSpace(.sRGB) ?? expected
        let tol: CGFloat = 0.005
        #expect(
            abs(actualSRGB.redComponent - expectedSRGB.redComponent) < tol &&
            abs(actualSRGB.greenComponent - expectedSRGB.greenComponent) < tol &&
            abs(actualSRGB.blueComponent - expectedSRGB.blueComponent) < tol &&
            abs(actualSRGB.alphaComponent - expectedSRGB.alphaComponent) < tol,
            "Token in \(appearance.name.rawValue) resolved to RGBA(\(actualSRGB.redComponent), \(actualSRGB.greenComponent), \(actualSRGB.blueComponent), \(actualSRGB.alphaComponent)) but expected RGBA(\(expectedSRGB.redComponent), \(expectedSRGB.greenComponent), \(expectedSRGB.blueComponent), \(expectedSRGB.alphaComponent))",
            sourceLocation: sourceLocation
        )
    }

    private static let aqua = NSAppearance(named: .aqua)!
    private static let darkAqua = NSAppearance(named: .darkAqua)!

    // MARK: Text

    @Test("textPrimary resolves to brand ink / foreground")
    func textPrimary() {
        expectColor(DesignTokens.Colors.textPrimary, equals: hex(Palette.ink), in: Self.aqua)
        expectColor(DesignTokens.Colors.textPrimary, equals: hex(Palette.foreground), in: Self.darkAqua)
    }

    @Test("textSecondary resolves correctly in light and dark")
    func textSecondary() {
        expectColor(DesignTokens.Colors.textSecondary, equals: hex(Palette.ink, 0.68), in: Self.aqua)
        expectColor(DesignTokens.Colors.textSecondary, equals: hex(Palette.foreground, 0.72), in: Self.darkAqua)
    }

    @Test("textTertiary resolves correctly in light and dark")
    func textTertiary() {
        expectColor(DesignTokens.Colors.textTertiary, equals: hex(Palette.ink, 0.50), in: Self.aqua)
        expectColor(DesignTokens.Colors.textTertiary, equals: hex(Palette.foreground, 0.52), in: Self.darkAqua)
    }

    @Test("textQuaternary resolves correctly in light and dark")
    func textQuaternary() {
        expectColor(DesignTokens.Colors.textQuaternary, equals: hex(Palette.ink, 0.32), in: Self.aqua)
        expectColor(DesignTokens.Colors.textQuaternary, equals: hex(Palette.foreground, 0.34), in: Self.darkAqua)
    }

    // MARK: Brand accents

    @Test("accentPrimary is the brand blue, lightened for dark")
    func accentPrimary() {
        expectColor(DesignTokens.Colors.accentPrimary, equals: hex(Palette.primary), in: Self.aqua)
        expectColor(DesignTokens.Colors.accentPrimary, equals: hex(Palette.primaryLight), in: Self.darkAqua)
    }

    @Test("accentHighlight uses the deepened cyan on light, raw cyan on dark")
    func accentHighlight() {
        expectColor(DesignTokens.Colors.accentHighlight, equals: hex(Palette.accentDeep), in: Self.aqua)
        expectColor(DesignTokens.Colors.accentHighlight, equals: hex(Palette.accent), in: Self.darkAqua)
    }

    @Test("accentSecondary is the brand violet, lightened for dark")
    func accentSecondary() {
        expectColor(DesignTokens.Colors.accentSecondary, equals: hex(Palette.secondary), in: Self.aqua)
        expectColor(DesignTokens.Colors.accentSecondary, equals: hex(Palette.secondaryLight), in: Self.darkAqua)
    }

    // MARK: Surfaces

    @Test("popupOverlay resolves correctly in light and dark")
    func popupOverlay() {
        // Light is the cool surfaceTint near-white; dark is brand navy, which
        // tints the whole popup without going opaque over the .popover material.
        expectColor(DesignTokens.Colors.popupOverlay,
                    equals: hex(Palette.surfaceTint, 0.50), in: Self.aqua)
        expectColor(DesignTokens.Colors.popupOverlay,
                    equals: hex(Palette.background, 0.52), in: Self.darkAqua)
    }

    @Test("popupGlassTint is lighter than popupOverlay in both appearances")
    func popupGlassTint() {
        // Deliberately weaker than popupOverlay: popupGlassBackground() stacks
        // only the window's own NSVisualEffectView, so the tint is the single
        // opacity layer rather than the third one.
        expectColor(DesignTokens.Colors.popupGlassTint,
                    equals: hex(Palette.surfaceTint, 0.30), in: Self.aqua)
        expectColor(DesignTokens.Colors.popupGlassTint,
                    equals: hex(Palette.background, 0.40), in: Self.darkAqua)
    }

    @Test("popupSpecular is a white highlight in both appearances")
    func popupSpecular() {
        // A specular highlight is light, not a hue, so both appearances are
        // white and only the alpha differs. Light glass can carry a strong
        // highlight; on dark it would blow out, hence the much lower alpha.
        expectColor(DesignTokens.Colors.popupSpecular,
                    equals: NSColor.white.withAlphaComponent(0.55), in: Self.aqua)
        expectColor(DesignTokens.Colors.popupSpecular,
                    equals: NSColor.white.withAlphaComponent(0.16), in: Self.darkAqua)
    }

    @Test("glassPillTint resolves correctly in light and dark")
    func glassPillTint() {
        expectColor(DesignTokens.Colors.glassPillTint,
                    equals: hex(Palette.primary, 0.10), in: Self.aqua)
        expectColor(DesignTokens.Colors.glassPillTint,
                    equals: hex(Palette.primaryLight, 0.14), in: Self.darkAqua)
    }

    @Test("recessedBackground resolves correctly in light and dark")
    func recessedBackground() {
        expectColor(DesignTokens.Colors.recessedBackground,
                    equals: hex(Palette.ink, 0.05), in: Self.aqua)
        expectColor(DesignTokens.Colors.recessedBackground,
                    equals: hex(Palette.background, 0.45), in: Self.darkAqua)
    }

    @Test("windowBackground resolves correctly in light and dark")
    func windowBackground() {
        expectColor(DesignTokens.Colors.windowBackground,
                    equals: hex(Palette.surfaceTint), in: Self.aqua)
        expectColor(DesignTokens.Colors.windowBackground,
                    equals: hex(Palette.background), in: Self.darkAqua)
    }

    // MARK: Borders

    @Test("menuBorder resolves correctly in light and dark")
    func menuBorder() {
        expectColor(DesignTokens.Colors.menuBorder, equals: hex(Palette.ink, 0.20), in: Self.aqua)
        expectColor(DesignTokens.Colors.menuBorder, equals: hex(Palette.foreground, 0.16), in: Self.darkAqua)
    }

    @Test("menuBorderHover is brand-tinted in both appearances")
    func menuBorderHover() {
        expectColor(DesignTokens.Colors.menuBorderHover,
                    equals: hex(Palette.primary, 0.45), in: Self.aqua)
        expectColor(DesignTokens.Colors.menuBorderHover,
                    equals: hex(Palette.primaryLight, 0.55), in: Self.darkAqua)
    }

    @Test("separator resolves correctly in light and dark")
    func separator() {
        expectColor(DesignTokens.Colors.separator, equals: hex(Palette.ink, 0.16), in: Self.aqua)
        expectColor(DesignTokens.Colors.separator, equals: hex(Palette.foreground, 0.14), in: Self.darkAqua)
    }

    // MARK: AutoEQ

    @Test("autoEQEmptyBorder resolves correctly in light and dark")
    func autoEQEmptyBorder() {
        expectColor(DesignTokens.Colors.autoEQEmptyBorder, equals: hex(Palette.ink, 0.22), in: Self.aqua)
        expectColor(DesignTokens.Colors.autoEQEmptyBorder, equals: hex(Palette.foreground, 0.14), in: Self.darkAqua)
    }

    @Test("autoEQEmptyIcon resolves correctly in light and dark")
    func autoEQEmptyIcon() {
        expectColor(DesignTokens.Colors.autoEQEmptyIcon, equals: hex(Palette.ink, 0.45), in: Self.aqua)
        expectColor(DesignTokens.Colors.autoEQEmptyIcon, equals: hex(Palette.foreground, 0.30), in: Self.darkAqua)
    }

    @Test("autoEQToggleLabel resolves correctly in light and dark")
    func autoEQToggleLabel() {
        expectColor(DesignTokens.Colors.autoEQToggleLabel, equals: hex(Palette.ink, 0.65), in: Self.aqua)
        expectColor(DesignTokens.Colors.autoEQToggleLabel, equals: hex(Palette.foreground, 0.55), in: Self.darkAqua)
    }

    // MARK: Rows & glass

    @Test("hoverSurface is a brand-blue wash in both appearances")
    func hoverSurface() {
        expectColor(DesignTokens.Colors.hoverSurface, equals: hex(Palette.primary, 0.10), in: Self.aqua)
        expectColor(DesignTokens.Colors.hoverSurface, equals: hex(Palette.primaryLight, 0.16), in: Self.darkAqua)
    }

    @Test("glassFill is transparent at rest in both appearances (flat-row design)")
    func glassFill() {
        expectColor(DesignTokens.Colors.glassFill, equals: NSColor.clear, in: Self.aqua)
        expectColor(DesignTokens.Colors.glassFill, equals: NSColor.clear, in: Self.darkAqua)
    }

    @Test("glassFillStrong resolves correctly in light and dark")
    func glassFillStrong() {
        expectColor(DesignTokens.Colors.glassFillStrong,
                    equals: hex(Palette.surfaceTint, 0.88), in: Self.aqua)
        expectColor(DesignTokens.Colors.glassFillStrong,
                    equals: hex(Palette.foreground, 0.10), in: Self.darkAqua)
    }

    @Test("glassRowBorder is transparent at rest in both appearances (flat-row design)")
    func glassRowBorder() {
        expectColor(DesignTokens.Colors.glassRowBorder, equals: NSColor.clear, in: Self.aqua)
        expectColor(DesignTokens.Colors.glassRowBorder, equals: NSColor.clear, in: Self.darkAqua)
    }

    @Test("glassRowBorderHover resolves correctly in light and dark")
    func glassRowBorderHover() {
        expectColor(DesignTokens.Colors.glassRowBorderHover,
                    equals: hex(Palette.primary, 0.22), in: Self.aqua)
        expectColor(DesignTokens.Colors.glassRowBorderHover,
                    equals: hex(Palette.primaryLight, 0.30), in: Self.darkAqua)
    }

    @Test("hudBorder resolves correctly in light and dark")
    func hudBorder() {
        expectColor(DesignTokens.Colors.hudBorder, equals: hex(Palette.ink, 0.16), in: Self.aqua)
        expectColor(DesignTokens.Colors.hudBorder, equals: hex(Palette.foreground, 0.12), in: Self.darkAqua)
    }

    @Test("sectionHeaderText resolves correctly in light and dark")
    func sectionHeaderText() {
        expectColor(DesignTokens.Colors.sectionHeaderText, equals: hex(Palette.ink, 0.62), in: Self.aqua)
        expectColor(DesignTokens.Colors.sectionHeaderText, equals: hex(Palette.foreground, 0.55), in: Self.darkAqua)
    }

    // MARK: Selection, focus & disabled

    @Test("selectionFill is a brand wash in both appearances")
    func selectionFill() {
        expectColor(DesignTokens.Colors.selectionFill, equals: hex(Palette.primary, 0.14), in: Self.aqua)
        expectColor(DesignTokens.Colors.selectionFill, equals: hex(Palette.primaryLight, 0.22), in: Self.darkAqua)
    }

    @Test("focusRing is cyan on dark so focus reads over the blue selection wash")
    func focusRing() {
        expectColor(DesignTokens.Colors.focusRing, equals: hex(Palette.primary, 0.55), in: Self.aqua)
        expectColor(DesignTokens.Colors.focusRing, equals: hex(Palette.accent, 0.65), in: Self.darkAqua)
    }

    @Test("controlFill and controlFillHover are distinct in both appearances")
    func controlFills() {
        expectColor(DesignTokens.Colors.controlFill, equals: hex(Palette.ink, 0.07), in: Self.aqua)
        expectColor(DesignTokens.Colors.controlFill, equals: hex(Palette.foreground, 0.10), in: Self.darkAqua)
        expectColor(DesignTokens.Colors.controlFillHover, equals: hex(Palette.ink, 0.11), in: Self.aqua)
        expectColor(DesignTokens.Colors.controlFillHover, equals: hex(Palette.foreground, 0.15), in: Self.darkAqua)
    }

    @Test("disabled tokens resolve correctly in light and dark")
    func disabledTokens() {
        expectColor(DesignTokens.Colors.disabledForeground, equals: hex(Palette.ink, 0.30), in: Self.aqua)
        expectColor(DesignTokens.Colors.disabledForeground, equals: hex(Palette.foreground, 0.30), in: Self.darkAqua)
        expectColor(DesignTokens.Colors.disabledFill, equals: hex(Palette.ink, 0.04), in: Self.aqua)
        expectColor(DesignTokens.Colors.disabledFill, equals: hex(Palette.foreground, 0.05), in: Self.darkAqua)
    }

    // MARK: Cards & badges

    @Test("eqCardBackground resolves correctly in light and dark")
    func eqCardBackground() {
        expectColor(DesignTokens.Colors.eqCardBackground,
                    equals: hex(Palette.surfaceTint, 0.80), in: Self.aqua)
        expectColor(DesignTokens.Colors.eqCardBackground,
                    equals: hex(Palette.foreground, 0.08), in: Self.darkAqua)
    }

    @Test("eqCardBorder resolves correctly in light and dark")
    func eqCardBorder() {
        expectColor(DesignTokens.Colors.eqCardBorder, equals: hex(Palette.ink, 0.08), in: Self.aqua)
        expectColor(DesignTokens.Colors.eqCardBorder, equals: hex(Palette.foreground, 0.12), in: Self.darkAqua)
    }

    @Test("deviceBadgeMonoFill resolves correctly in light and dark")
    func deviceBadgeMonoFill() {
        expectColor(DesignTokens.Colors.deviceBadgeMonoFill, equals: hex(Palette.ink, 0.10), in: Self.aqua)
        expectColor(DesignTokens.Colors.deviceBadgeMonoFill, equals: hex(Palette.foreground, 0.12), in: Self.darkAqua)
    }

    @Test("deviceBadgeMonoForeground resolves correctly in light and dark")
    func deviceBadgeMonoForeground() {
        expectColor(DesignTokens.Colors.deviceBadgeMonoForeground, equals: hex(Palette.ink, 0.65), in: Self.aqua)
        expectColor(DesignTokens.Colors.deviceBadgeMonoForeground, equals: hex(Palette.foreground, 0.72), in: Self.darkAqua)
    }

    @Test("badge gradient runs brand blue into brand violet")
    func badgeGradient() {
        expectColor(DesignTokens.Colors.badgeGradientStart, equals: hex(Palette.primary), in: Self.aqua)
        expectColor(DesignTokens.Colors.badgeGradientEnd, equals: hex(Palette.secondary), in: Self.aqua)
        expectColor(DesignTokens.Colors.badgeGradientStart, equals: hex(Palette.primaryLight), in: Self.darkAqua)
        expectColor(DesignTokens.Colors.badgeGradientEnd, equals: hex(Palette.secondaryLight), in: Self.darkAqua)
    }
}
