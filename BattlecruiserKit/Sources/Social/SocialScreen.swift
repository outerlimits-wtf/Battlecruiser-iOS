import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBClient
import PubDBModels

/// The Social tab: what people have been adding, who adds the most, and the
/// boards the server offers. The web's menu pages, as a list.
public struct SocialScreen: View {
    private let source: any CommunitySource
    private let boards: [BoardInfo]
    private let isSignedIn: Bool
    private let location: Coordinate?
    private let onOpenPub: (PubLink) -> Void
    private let profileDestination: (ProfileLink) -> AnyView

    public init(
        source: any CommunitySource,
        boards: [BoardInfo],
        isSignedIn: Bool,
        location: Coordinate?,
        onOpenPub: @escaping (PubLink) -> Void,
        profileDestination: @escaping (ProfileLink) -> AnyView
    ) {
        self.source = source
        self.boards = boards
        self.isSignedIn = isSignedIn
        self.location = location
        self.onOpenPub = onOpenPub
        self.profileDestination = profileDestination
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.m) {
                    NavigationLink {
                        LatestPage(source: source, isSignedIn: isSignedIn, onOpenPub: onOpenPub)
                    } label: {
                        MenuRow(emoji: "🕑", title: "Latest updates", blurb: "What people have been adding")
                    }
                    NavigationLink {
                        LeaderboardPage(source: source)
                    } label: {
                        MenuRow(emoji: "🏆", title: "Leaderboard", blurb: "Who is actually mashing work")
                    }
                    if !boards.isEmpty {
                        SectionHeader("Boards").padding(.top, Metrics.m)
                        ForEach(boards) { board in
                            NavigationLink {
                                BoardPage(source: source, info: board, location: location, onOpenPub: onOpenPub)
                            } label: {
                                MenuRow(emoji: board.emoji, title: board.title, blurb: board.blurb)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(Metrics.l)
            }
            .background(Palette.canvas)
            .navigationTitle("Social")
            .navigationDestination(for: ProfileLink.self, destination: profileDestination)
        }
    }
}
