// SoundPilot/Views/Settings/Tabs/AboutTab.swift
import AppKit
import SwiftUI

@MainActor
struct AboutTab: View {
    static let authorName = "iamnabink"
    static let authorURL = URL(string: "https://github.com/iamnabink")!
    static let repositoryURL = URL(string: "https://github.com/iamnabink/soundpilot-macos-volume-mixer")!
    static let issuesURL = URL(string: "https://github.com/iamnabink/soundpilot-macos-volume-mixer/issues")!
    static let releasesURL = URL(string: "https://github.com/iamnabink/soundpilot-macos-volume-mixer/releases")!

    private var versionShort: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    private var yearText: String {
        let startYear = 2026
        let currentYear = Calendar.current.component(.year, from: .now)
        return startYear == currentYear ? "\(startYear)" : "\(startYear)-\(currentYear)"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 96, height: 96)

                Text("SoundPilot")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("Volume Mixer")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.accentPrimary)

                Text("Version \(versionShort) (\(buildNumber))")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                authorLine
                    .padding(.top, 4)
            }

            Spacer()

            links
                .padding(.bottom, 12)

            footer
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var authorLine: some View {
        HStack(spacing: 4) {
            Text("Made by")
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            Link(Self.authorName, destination: Self.authorURL)
                .foregroundStyle(DesignTokens.Colors.accentPrimary)
                .fontWeight(.semibold)
        }
        .font(.system(size: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Made by \(Self.authorName). Opens the author's GitHub profile.")
    }

    private var links: some View {
        HStack(spacing: 18) {
            Link(destination: Self.repositoryURL) {
                Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            Link(destination: Self.releasesURL) {
                Label("Releases", systemImage: "arrow.down.circle")
            }
            Link(destination: Self.issuesURL) {
                Label("Report an Issue", systemImage: "ladybug")
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(DesignTokens.Colors.accentPrimary)
    }

    private var footer: some View {
        Text("© \(yearText) \(Self.authorName) · Free for personal & educational use · Commercial use requires permission")
            .font(.system(size: 10))
            .foregroundStyle(DesignTokens.Colors.textTertiary)
    }
}
