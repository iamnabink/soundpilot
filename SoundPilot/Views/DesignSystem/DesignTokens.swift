// SoundPilot/Views/DesignSystem/DesignTokens.swift
import SwiftUI
import AppKit

/// Design System tokens for SoundPilot UI
/// Centralized values for colors, typography, spacing, dimensions, and animations
enum DesignTokens {

    // MARK: - Internal helpers

    /// Builds a SwiftUI Color that resolves to `light` or `dark` based on the
    /// effective NSAppearance at draw time. SwiftUI re-resolves automatically
    /// when the appearance changes (system toggle or override change) because
    /// `Color(nsColor:)` preserves the underlying NSColor's adaptability.
    ///
    /// `name` is NSColor's caching key. Pass a unique name per token; two
    /// dynamic colors sharing a name silently resolve to the same instance.
    /// `DesignTokensDynamicResolutionTests` enforces uniqueness by asserting
    /// per-token RGBA values.
    static func dynamicColor(name: String, light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: NSColor.Name(name)) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }

    // MARK: - Brand Palette

    /// The SoundPilot brand palette. These five values are the only literal
    /// colors in the app's chromatic system; every semantic token below is
    /// one of them (or a documented derivative) plus an alpha.
    ///
    /// The raw palette is tuned for a dark surface, so light-appearance
    /// tokens use derived variants: `accent` and `foreground` have too little
    /// luminance contrast against white to carry text or hairlines, and
    /// `primary`/`secondary` have too little against `background` to carry
    /// them on dark. Each derivative documents the mix that produced it.
    enum Brand {
        // MARK: Core palette

        /// #1355D9 — primary brand blue. Buttons, sliders, selection.
        static let primary = srgb(0x1355D9)

        /// #06194D — brand background navy. Dark-appearance surfaces and,
        /// as `ink`, light-appearance text.
        static let background = srgb(0x06194D)

        /// #19D9F5 — accent cyan. Live/active highlights on dark surfaces.
        static let accent = srgb(0x19D9F5)

        /// #8B35F5 — secondary violet. Paired with `primary` in gradients.
        static let secondary = srgb(0x8B35F5)

        /// #D8E2F4 — foreground mist. Dark-appearance text and hairlines.
        static let foreground = srgb(0xD8E2F4)

        // MARK: Derived variants

        /// #5A88E4 — `primary` mixed 30% toward white. Dark-appearance
        /// primary: 4.9:1 against `background`, where raw `primary` is 2.7:1.
        /// Mirrored by the dark entry of the `AccentColor` asset.
        static let primaryLight = srgb(0x5A88E4)

        /// #0F42A9 — `primary` scaled to 78% luminance. Pressed/active
        /// emphasis in light appearance.
        static let primaryDark = srgb(0x0F42A9)

        /// #0D6C7A — `accent` scaled to 50%. Light-appearance accent:
        /// 6.1:1 on white, where raw `accent` is 1.7:1.
        static let accentDeep = srgb(0x0D6C7A)

        /// #A868F8 — `secondary` mixed 25% toward white, for dark surfaces.
        static let secondaryLight = srgb(0xA868F8)

        /// #EDF2FA — `foreground` mixed 55% toward white. The light-appearance
        /// surface tint: a cool near-white that keeps the glass on-brand
        /// instead of neutral gray.
        static let surfaceTint = srgb(0xEDF2FA)

        /// Light-appearance text and hairline color. Same value as
        /// `background`; named separately because the role is text, not
        /// surface. 16.8:1 on white.
        static let ink = background

        /// Builds an sRGB NSColor from a `0xRRGGBB` literal so palette values
        /// can be read straight off the brand spec.
        static func srgb(_ hex: UInt32, alpha: CGFloat = 1.0) -> NSColor {
            NSColor(
                srgbRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
                green: CGFloat((hex >> 8) & 0xFF) / 255.0,
                blue: CGFloat(hex & 0xFF) / 255.0,
                alpha: alpha
            )
        }
    }

    // MARK: - Colors

    enum Colors {
        // MARK: Text

        /// Primary text. Brand ink on light, brand foreground on dark.
        static let textPrimary = dynamicColor(
            name: "textPrimary",
            light: Brand.ink,
            dark: Brand.foreground
        )

        /// Secondary text — supporting labels that still need to be read
        /// comfortably (5.9:1 light / 8.9:1 dark).
        static let textSecondary = dynamicColor(
            name: "textSecondary",
            light: Brand.ink.withAlphaComponent(0.68),
            dark: Brand.foreground.withAlphaComponent(0.72)
        )

        /// Tertiary text — for less important content.
        static let textTertiary = dynamicColor(
            name: "textTertiary",
            light: Brand.ink.withAlphaComponent(0.50),
            dark: Brand.foreground.withAlphaComponent(0.52)
        )

        /// Quaternary text — very subtle.
        static let textQuaternary = dynamicColor(
            name: "textQuaternary",
            light: Brand.ink.withAlphaComponent(0.32),
            dark: Brand.foreground.withAlphaComponent(0.34)
        )

        // MARK: Interactive

        /// Default interactive element color
        static let interactiveDefault = dynamicColor(
            name: "interactiveDefault",
            light: Brand.ink.withAlphaComponent(0.62),
            dark: Brand.foreground.withAlphaComponent(0.68)
        )

        /// Hovered interactive element color
        static let interactiveHover = dynamicColor(
            name: "interactiveHover",
            light: Brand.ink.withAlphaComponent(0.88),
            dark: Brand.foreground.withAlphaComponent(0.92)
        )

        /// Active/pressed interactive element color
        static let interactiveActive = dynamicColor(
            name: "interactiveActive",
            light: Brand.primaryDark,
            dark: Brand.primaryLight
        )

        /// Brand accent for selections and primary actions. Matches the
        /// `AccentColor` asset, so tokenized surfaces and the AppKit controls
        /// that read the global accent (toggles, carets, focus rings) agree.
        static let accentPrimary = dynamicColor(
            name: "accentPrimary",
            light: Brand.primary,
            dark: Brand.primaryLight
        )

        /// Cyan highlight for live/energetic states (playing, connected).
        static let accentHighlight = dynamicColor(
            name: "accentHighlight",
            light: Brand.accentDeep,
            dark: Brand.accent
        )

        /// Violet companion to `accentPrimary`, used as the far stop of brand
        /// gradients and for AutoEQ affordances.
        static let accentSecondary = dynamicColor(
            name: "accentSecondary",
            light: Brand.secondary,
            dark: Brand.secondaryLight
        )

        /// Mute button active (muted state) - red for visibility.
        /// Deliberately outside the brand palette: mute is a state warning and
        /// has to stay recognizably red. See `MuteButtonColorInvariantTests`.
        static let mutedIndicator = Color(nsColor: .systemRed).opacity(0.85)

        /// Destructive actions (reset, remove, error text).
        static let destructive = Color(nsColor: .systemRed).opacity(0.9)

        /// Caution/degraded state (media-key tap offline, permissions missing).
        static let warning = Color(nsColor: .systemOrange)

        /// Favorited/starred marker.
        static let favorite = Color(nsColor: .systemYellow)

        /// Default device indicator — uses the brand accent
        static let defaultDevice = accentPrimary

        // MARK: Separators & Borders

        /// Hairline separator between grouped content.
        static let separator = dynamicColor(
            name: "separator",
            light: Brand.ink.withAlphaComponent(0.16),
            dark: Brand.foreground.withAlphaComponent(0.14)
        )

        /// Subtle border for glass elements
        static let glassBorder = dynamicColor(
            name: "glassBorder",
            light: Brand.ink.withAlphaComponent(0.12),
            dark: Brand.foreground.withAlphaComponent(0.10)
        )

        /// Hover-state border
        static let glassBorderHover = dynamicColor(
            name: "glassBorderHover",
            light: Brand.primary.withAlphaComponent(0.40),
            dark: Brand.primaryLight.withAlphaComponent(0.50)
        )

        // MARK: Slider

        /// Slider track background (unfilled) - visible on glass
        static let sliderTrack = dynamicColor(
            name: "sliderTrack",
            light: Brand.ink.withAlphaComponent(0.14),
            dark: Brand.foreground.withAlphaComponent(0.18)
        )

        /// Slider filled track - brand primary
        static let sliderFill = accentPrimary

        /// Slider thumb
        static let sliderThumb = dynamicColor(
            name: "sliderThumb",
            light: NSColor.white,
            dark: Brand.surfaceTint
        )

        /// Unity marker on slider
        static let unityMarker = dynamicColor(
            name: "unityMarker",
            light: Brand.ink.withAlphaComponent(0.42),
            dark: Brand.foreground.withAlphaComponent(0.45)
        )

        // MARK: Control Elements

        /// EQ/slider thumb background
        static let thumbBackground = sliderThumb

        /// EQ/slider thumb center dot — brand navy so the thumb reads as a
        /// SoundPilot control rather than a neutral puck.
        static let thumbDot = dynamicColor(
            name: "thumbDot",
            light: Brand.background.withAlphaComponent(0.78),
            dark: Brand.background.withAlphaComponent(0.85)
        )

        /// Neutral fill for inline controls (steppers, editable fields,
        /// segmented backgrounds) at rest.
        static let controlFill = dynamicColor(
            name: "controlFill",
            light: Brand.ink.withAlphaComponent(0.07),
            dark: Brand.foreground.withAlphaComponent(0.10)
        )

        /// `controlFill` under the pointer.
        static let controlFillHover = dynamicColor(
            name: "controlFillHover",
            light: Brand.ink.withAlphaComponent(0.11),
            dark: Brand.foreground.withAlphaComponent(0.15)
        )

        // MARK: Selection, Focus & Disabled

        /// Wash behind a selected or keyboard-highlighted menu/list item.
        static let selectionFill = dynamicColor(
            name: "selectionFill",
            light: Brand.primary.withAlphaComponent(0.14),
            dark: Brand.primaryLight.withAlphaComponent(0.22)
        )

        /// Edge of a selected control (segmented picker, theme tile).
        static let selectionBorder = accentPrimary

        /// Keyboard-focus ring. Cyan on dark so focus is distinguishable from
        /// the blue selection wash it sits on.
        static let focusRing = dynamicColor(
            name: "focusRing",
            light: Brand.primary.withAlphaComponent(0.55),
            dark: Brand.accent.withAlphaComponent(0.65)
        )

        /// Text/icon color for a disabled control — below interactive
        /// contrast on purpose, still legible as a label.
        static let disabledForeground = dynamicColor(
            name: "disabledForeground",
            light: Brand.ink.withAlphaComponent(0.30),
            dark: Brand.foreground.withAlphaComponent(0.30)
        )

        /// Fill for a disabled control.
        static let disabledFill = dynamicColor(
            name: "disabledFill",
            light: Brand.ink.withAlphaComponent(0.04),
            dark: Brand.foreground.withAlphaComponent(0.05)
        )

        // MARK: Glass Effects

        /// Popup background overlay. Sits over NSVisualEffectView's `.popover`
        /// material. Light is the cool `surfaceTint` near-white so the popup
        /// reads as crisp brand glass over arbitrary wallpapers; dark is the
        /// brand navy, which tints the whole surface without going opaque.
        static let popupOverlay = dynamicColor(
            name: "popupOverlay",
            light: Brand.surfaceTint.withAlphaComponent(0.50),
            dark: Brand.background.withAlphaComponent(0.52)
        )

        /// Popup tint used by `popupGlassBackground()`. Lighter than
        /// `popupOverlay` because that modifier stacks only one material:
        /// FluidMenuBarExtra already makes the window's content view an
        /// NSVisualEffectView, so the popup adds a tint rather than a second
        /// blur. The lower alpha is what lets the desktop read through the
        /// surface the way Control Center's does.
        static let popupGlassTint = dynamicColor(
            name: "popupGlassTint",
            light: Brand.surfaceTint.withAlphaComponent(0.30),
            dark: Brand.background.withAlphaComponent(0.40)
        )

        /// Specular highlight along the popup's top edge. Real glass catches
        /// light where it meets the bezel; this gradient stand-in is what
        /// separates the surface from the wallpaper behind it. White in both
        /// appearances, because a highlight is light rather than a hue.
        static let popupSpecular = dynamicColor(
            name: "popupSpecular",
            light: NSColor.white.withAlphaComponent(0.55),
            dark: NSColor.white.withAlphaComponent(0.16)
        )

        /// Tint applied to Liquid Glass pills on macOS 26. Weak on purpose:
        /// the glass supplies the depth, the tint only keeps the controls on
        /// brand instead of reading as neutral system chrome.
        static let glassPillTint = dynamicColor(
            name: "glassPillTint",
            light: Brand.primary.withAlphaComponent(0.10),
            dark: Brand.primaryLight.withAlphaComponent(0.14)
        )

        /// Recessed panel background (EQ panel). Light mode is nearly flush
        /// with the surrounding glass; opaque cards do the floating instead.
        static let recessedBackground = dynamicColor(
            name: "recessedBackground",
            light: Brand.ink.withAlphaComponent(0.05),
            dark: Brand.background.withAlphaComponent(0.45)
        )

        // MARK: Menu/Picker

        /// Menu button background
        static let menuBackground: Color = .clear

        /// Menu button border.
        static let menuBorder = dynamicColor(
            name: "menuBorder",
            light: Brand.ink.withAlphaComponent(0.20),
            dark: Brand.foreground.withAlphaComponent(0.16)
        )

        /// Menu button border on hover — brand primary, so the hover state
        /// reads at a glance in both appearances.
        static let menuBorderHover = dynamicColor(
            name: "menuBorderHover",
            light: Brand.primary.withAlphaComponent(0.45),
            dark: Brand.primaryLight.withAlphaComponent(0.55)
        )

        /// Picker background
        static let pickerBackground = controlFill

        /// Picker hover
        static let pickerHover = dynamicColor(
            name: "pickerHover",
            light: Brand.primary.withAlphaComponent(0.10),
            dark: Brand.primaryLight.withAlphaComponent(0.16)
        )

        // MARK: Hover & Glass Surface

        /// Hover background for tappable rows. With flat-row design (no
        /// resting fill or border), this is the primary "this row is active"
        /// affordance, so it needs to read clearly without being heavy.
        /// Brand-tinted rather than neutral: hovering anything in SoundPilot
        /// washes it blue. Matches the macOS-native System Settings pattern.
        static let hoverSurface = dynamicColor(
            name: "hoverSurface",
            light: Brand.primary.withAlphaComponent(0.10),
            dark: Brand.primaryLight.withAlphaComponent(0.16)
        )

        /// Default row fill. Transparent — rows blend with the popup
        /// material at rest, like System Settings / Notification Center.
        /// Hover reveals `hoverSurface` as the meaningful interaction signal.
        static let glassFill = dynamicColor(
            name: "glassFill",
            light: NSColor.clear,
            dark: NSColor.clear
        )

        /// Stronger glass-card fill for emphasised badges and sheet inserts
        /// (DEFAULT pill, AutoEQ search panel, device-detail sheet). Not used
        /// for default row backgrounds.
        static let glassFillStrong = dynamicColor(
            name: "glassFillStrong",
            light: Brand.surfaceTint.withAlphaComponent(0.88),
            dark: Brand.foreground.withAlphaComponent(0.10)
        )

        /// Default row border. Transparent — flat rows have no resting edge.
        static let glassRowBorder = dynamicColor(
            name: "glassRowBorder",
            light: NSColor.clear,
            dark: NSColor.clear
        )

        /// Hovered row edge — soft hairline visible only when the row is
        /// being interacted with. Pairs with `hoverSurface` to define the
        /// active row.
        static let glassRowBorderHover = dynamicColor(
            name: "glassRowBorderHover",
            light: Brand.primary.withAlphaComponent(0.22),
            dark: Brand.primaryLight.withAlphaComponent(0.30)
        )

        /// HUD panel hairline border (Tahoe + Classic).
        static let hudBorder = dynamicColor(
            name: "hudBorder",
            light: Brand.ink.withAlphaComponent(0.16),
            dark: Brand.foreground.withAlphaComponent(0.12)
        )

        // MARK: Cards & Badges

        /// Lifted-card fill used by the EQ panel and Settings sections.
        /// Light reads as a cool near-white card on the popup glass; dark
        /// reads as a subtle translucent surface on the navy glass. Pairs
        /// with `eqCardBorder` for the hairline edge.
        static let eqCardBackground = dynamicColor(
            name: "eqCardBackground",
            light: Brand.surfaceTint.withAlphaComponent(0.80),
            dark: Brand.foreground.withAlphaComponent(0.08)
        )

        /// Hairline border for the lifted card. Visible enough to define
        /// the edge, quiet enough to read as part of the glass family.
        static let eqCardBorder = dynamicColor(
            name: "eqCardBorder",
            light: Brand.ink.withAlphaComponent(0.08),
            dark: Brand.foreground.withAlphaComponent(0.12)
        )

        /// Start of the brand gradient on a selected device badge.
        static let badgeGradientStart = accentPrimary

        /// End of the brand gradient on a selected device badge — the violet
        /// secondary, echoing the app icon's blue-to-violet sweep.
        static let badgeGradientEnd = accentSecondary

        /// Foreground of a selected device badge, on the brand gradient.
        static let badgeSelectedForeground = dynamicColor(
            name: "badgeSelectedForeground",
            light: NSColor.white,
            dark: Brand.surfaceTint
        )

        /// Monochrome circular badge fill used on non-selected device rows.
        static let deviceBadgeMonoFill = dynamicColor(
            name: "deviceBadgeMonoFill",
            light: Brand.ink.withAlphaComponent(0.10),
            dark: Brand.foreground.withAlphaComponent(0.12)
        )

        /// Foreground color for the device-badge SF symbol on a non-selected
        /// row. Selected rows use `badgeSelectedForeground`.
        static let deviceBadgeMonoForeground = dynamicColor(
            name: "deviceBadgeMonoForeground",
            light: Brand.ink.withAlphaComponent(0.65),
            dark: Brand.foreground.withAlphaComponent(0.72)
        )

        /// Section-header text ("APPS", "GENERAL", etc.). The system
        /// `tertiaryLabelColor` is too faint as a section divider; this token
        /// gives the headers Apple-app-style readability in brand ink.
        static let sectionHeaderText = dynamicColor(
            name: "sectionHeaderText",
            light: Brand.ink.withAlphaComponent(0.62),
            dark: Brand.foreground.withAlphaComponent(0.55)
        )

        // MARK: Window Chrome

        /// Settings window background.
        static let windowBackground = dynamicColor(
            name: "windowBackground",
            light: Brand.surfaceTint,
            dark: Brand.background
        )

        /// Inset content surface inside the Settings window.
        static let contentBackground = dynamicColor(
            name: "contentBackground",
            light: NSColor.white.withAlphaComponent(0.70),
            dark: Brand.foreground.withAlphaComponent(0.06)
        )

        // MARK: VU Meter (Professional audio standard - NOT themed)

        /// VU meter green segments (bars 0-3, safe levels)
        static let vuGreen = Color(red: 0.20, green: 0.78, blue: 0.40)

        /// VU meter yellow segments (bars 4-5, caution)
        static let vuYellow = Color(red: 0.95, green: 0.75, blue: 0.20)

        /// VU meter orange segment (bar 6, warning)
        static let vuOrange = Color(red: 0.95, green: 0.50, blue: 0.20)

        /// VU meter red segment (bar 7, peak/clip)
        static let vuRed = Color(red: 0.90, green: 0.25, blue: 0.25)

        /// VU meter unlit bar color (matches sliderTrack for visual consistency)
        static let vuUnlit = sliderTrack

        /// VU meter muted state
        static let vuMuted = dynamicColor(
            name: "vuMuted",
            light: Brand.ink.withAlphaComponent(0.35),
            dark: Brand.foreground.withAlphaComponent(0.35)
        )

        // MARK: AutoEQ

        /// AutoEQ empty-state dashed border.
        static let autoEQEmptyBorder = dynamicColor(
            name: "autoEQEmptyBorder",
            light: Brand.ink.withAlphaComponent(0.22),
            dark: Brand.foreground.withAlphaComponent(0.14)
        )

        /// AutoEQ empty-state icon color.
        static let autoEQEmptyIcon = dynamicColor(
            name: "autoEQEmptyIcon",
            light: Brand.ink.withAlphaComponent(0.45),
            dark: Brand.foreground.withAlphaComponent(0.30)
        )

        /// AutoEQ toggle label text color (Correction / Preamp labels).
        static let autoEQToggleLabel = dynamicColor(
            name: "autoEQToggleLabel",
            light: Brand.ink.withAlphaComponent(0.65),
            dark: Brand.foreground.withAlphaComponent(0.55)
        )

        // MARK: HUD

        /// Active dot in Tahoe HUD tick track
        static let hudDotActive = dynamicColor(
            name: "hudDotActive",
            light: Brand.ink.withAlphaComponent(0.85),
            dark: Brand.foreground.withAlphaComponent(0.88)
        )

        /// Inactive dot in Tahoe HUD tick track
        static let hudDotInactive = dynamicColor(
            name: "hudDotInactive",
            light: Brand.ink.withAlphaComponent(0.18),
            dark: Brand.foreground.withAlphaComponent(0.22)
        )

        /// Active tile in Classic HUD segment row
        static let hudTileActive = dynamicColor(
            name: "hudTileActive",
            light: Brand.ink.withAlphaComponent(0.72),
            dark: Brand.foreground.withAlphaComponent(0.78)
        )

        /// Inactive tile in Classic HUD segment row
        static let hudTileInactive = dynamicColor(
            name: "hudTileInactive",
            light: Brand.ink.withAlphaComponent(0.20),
            dark: Brand.foreground.withAlphaComponent(0.24)
        )
    }

    // MARK: - Typography

    enum Typography {
        /// Section header text (e.g., "OUTPUT DEVICES") - prominent and bold
        static let sectionHeader = Font.system(size: 12, weight: .bold)

        /// Section header letter spacing (tighter at larger size)
        static let sectionHeaderTracking: CGFloat = 1.2

        /// App/device name in rows
        static let rowName = Font.system(size: 13, weight: .regular)

        /// Bold variant for default device name
        static let rowNameBold = Font.system(size: 13, weight: .semibold)

        /// Volume percentage display
        static let percentage = Font.system(size: 11, weight: .medium, design: .monospaced)

        /// Small caption text
        static let caption = Font.system(size: 10, weight: .regular)

        /// Device picker text
        static let pickerText = Font.system(size: 11, weight: .regular)

        /// EQ frequency labels
        static let eqLabel = Font.system(size: 9, weight: .medium, design: .monospaced)

        /// AutoEQ card profile name
        static let cardProfileName = Font.system(size: 12, weight: .semibold)

        /// AutoEQ card source/measuredBy
        static let cardSource = Font.system(size: 9, weight: .regular)

        /// Settings card header (sentence case, 13pt semibold)
        static let cardHeader = Font.system(size: 13, weight: .semibold)

        /// Settings row description (11pt regular, tertiary)
        static let rowDescription = Font.system(size: 11, weight: .regular)
    }

    // MARK: - Spacing (standard 1× multiplier)

    enum Spacing {
        /// 2pt - Extra extra small
        static let xxs: CGFloat = 2

        /// 4pt - Extra small
        static let xs: CGFloat = 4

        /// 8pt - Small
        static let sm: CGFloat = 8

        /// 12pt - Medium
        static let md: CGFloat = 12

        /// 16pt - Large
        static let lg: CGFloat = 16

        /// 20pt - Extra large
        static let xl: CGFloat = 20

        /// 24pt - Extra extra large
        static let xxl: CGFloat = 24
    }

    // MARK: - Dimensions

    enum Dimensions {
        // MARK: Base Configuration

        /// Main popup width
        static let popupWidth: CGFloat = 510

        /// Content padding
        static var contentPadding: CGFloat { Spacing.lg }

        /// Available content width after padding
        static var contentWidth: CGFloat {
            popupWidth - (contentPadding * 2)
        }

        // MARK: Fixed Dimensions

        /// Max height for scrollable content
        static let maxScrollHeight: CGFloat = 400

        // MARK: Corner Radii (rounded style - 10pt)

        /// Corner radius for popup
        static let cornerRadius: CGFloat = 12

        /// Corner radius for row cards (glass bars)
        static let rowRadius: CGFloat = 10

        /// Corner radius for buttons/pickers
        static let buttonRadius: CGFloat = 6

        /// App/device icon size
        static let iconSize: CGFloat = 22

        /// Small icon size
        static let iconSizeSmall: CGFloat = 14

        // MARK: Slider Dimensions (minimal style)

        /// Slider track height
        static let sliderTrackHeight: CGFloat = 3

        /// Slider thumb width (pill shape)
        static let sliderThumbWidth: CGFloat = 16

        /// Slider thumb height (pill shape)
        static let sliderThumbHeight: CGFloat = 10

        /// Circular thumb size
        static let sliderThumbSize: CGFloat = 12

        /// Minimum touch target
        static let minTouchTarget: CGFloat = 16

        /// Row content height
        static let rowContentHeight: CGFloat = 28

        // MARK: Component Widths

        /// Slider width
        static let sliderWidth: CGFloat = 140

        /// Minimum slider width
        static let sliderMinWidth: CGFloat = 120

        /// Percentage text width (fixed to prevent layout shift)
        static let percentageWidth: CGFloat = 40

        // MARK: VU Meter

        /// VU meter bar count
        static let vuMeterBarCount: Int = 8

        // MARK: Settings Row

        /// Settings row icon column width
        static let settingsIconWidth: CGFloat = 24

        /// Settings slider width
        static let settingsSliderWidth: CGFloat = 200

        /// Settings percentage text width
        static let settingsPercentageWidth: CGFloat = 44

        /// Settings picker width
        static let settingsPickerWidth: CGFloat = 120

    }

    // MARK: - Animation (smooth style - macOS-like springs)

    enum Animation {
        /// Quick spring for small elements
        static let quick = SwiftUI.Animation.spring(response: 0.2, dampingFraction: 0.85)

        /// Hover transition (brief and precise per HIG)
        static let hover = SwiftUI.Animation.easeOut(duration: 0.12)

        /// VU meter level change
        static let vuMeterLevel = SwiftUI.Animation.linear(duration: 0.05)
    }

    // MARK: - Timing

    enum Timing {
        /// VU meter update interval (30fps)
        static let vuMeterUpdateInterval: TimeInterval = 1.0 / 30.0

        /// VU meter peak hold duration
        static let vuMeterPeakHold: TimeInterval = 0.5
    }

}
