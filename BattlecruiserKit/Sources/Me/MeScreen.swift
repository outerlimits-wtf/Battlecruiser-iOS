import SwiftUI
import Account
import AppEnvironment
import DesignSystem

/// The Me tab: the account, how the app looks, and what this is.
public struct MeScreen: View {
    private let session: SessionModel
    private let onOpenProfile: (String) -> Void
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system

    public init(session: SessionModel, onOpenProfile: @escaping (String) -> Void) {
        self.session = session
        self.onOpenProfile = onOpenProfile
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.xl) {
                    AccountBlock(session: session, onOpenProfile: onOpenProfile)
                    VStack(alignment: .leading, spacing: Metrics.s) {
                        SectionHeader("Appearance")
                        Picker("Appearance", selection: $theme) {
                            ForEach(ThemePreference.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    NavigationLink {
                        AboutPage()
                    } label: {
                        MenuRow(emoji: "ℹ️", title: "About", blurb: "What this is, and why you should care")
                    }
                    .buttonStyle(.plain)
                    Text("PubDB · © OpenStreetMap contributors, ODbL")
                        .font(Typography.micro)
                        .foregroundStyle(Palette.inkFaint)
                }
                .padding(Metrics.l)
            }
            .background(Palette.canvas)
            .navigationTitle("Me")
        }
    }
}
