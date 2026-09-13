// SoundPilot/Views/DesignSystem/GlassSurface.swift
// Liquid Glass helpers with a pre-Tahoe fallback.
//
// macOS 26 added `glassEffect`, a genuinely refractive surface with a specular
// rim — the treatment Control Center and the system menus use. macOS 15 has no
// equivalent, so every helper here degrades to the flat token fill the app
// already shipped. Call sites get one API and never branch on availability
// themselves, which keeps the availability check in exactly one file.
//
// Why the popup surface itself is NOT Liquid Glass: FluidMenuBarExtra already
// makes the window's content view an NSVisualEffectView, so the backdrop is
// blurred before SwiftUI draws anything. Layering glass over an existing blur
// samples mush and reads flat. Control Center works the same way — one blurred
// backdrop, with glass *controls* floating on it — so that is the split here.

import SwiftUI

/// Builds a `Glass` value from optional tint and interactivity.
/// Split out because `Glass` itself is macOS 26+, so it cannot appear in a
/// signature that older systems compile against.
@available(macOS 26.0, *)
private func soundPilotGlass(tint: Color?, interactive: Bool) -> Glass {
    var glass: Glass = .regular
    if let tint {
        glass = glass.tint(tint)
    }
    if interactive {
        glass = glass.interactive()
    }
    return glass
}

extension View {
    /// Applies a Liquid Glass surface behind the view on macOS 26, and the
    /// supplied flat fill on earlier systems.
    ///
    /// - Parameters:
    ///   - cornerRadius: Corner radius of the glass shape.
    ///   - tint: Optional brand tint for the glass. Ignored pre-26.
    ///   - interactive: Whether the glass reacts to press and hover. Use for
    ///     controls, not for static surfaces.
    ///   - fallback: Flat fill drawn on macOS 15, where no glass exists.
    @ViewBuilder
    func liquidGlass(
        cornerRadius: CGFloat,
        tint: Color? = nil,
        interactive: Bool = false,
        fallback: Color
    ) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(
                soundPilotGlass(tint: tint, interactive: interactive),
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fallback)
            }
        }
    }
}

/// A standalone glass panel for use inside `.background { }`, where the caller
/// needs a *view* rather than a modifier — notably the row hover surface, which
/// renders conditionally and must not participate in layout.
struct GlassPanel: View {
    let cornerRadius: CGFloat
    var tint: Color?
    var interactive: Bool = false
    let fallback: Color

    var body: some View {
        if #available(macOS 26.0, *) {
            Color.clear
                .glassEffect(
                    soundPilotGlass(tint: tint, interactive: interactive),
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(fallback)
        }
    }
}

// MARK: - Previews

#Preview("Glass Pills") {
    VStack(spacing: 16) {
        Text("Liquid Glass pill")
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .liquidGlass(
                cornerRadius: DesignTokens.Dimensions.buttonRadius,
                tint: DesignTokens.Colors.glassPillTint,
                interactive: true,
                fallback: DesignTokens.Colors.glassFillStrong
            )

        Text("Row hover surface")
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                GlassPanel(
                    cornerRadius: DesignTokens.Dimensions.rowRadius,
                    tint: DesignTokens.Colors.glassPillTint,
                    fallback: DesignTokens.Colors.hoverSurface
                )
            }
    }
    .padding(32)
    .darkGlassBackground()
}
