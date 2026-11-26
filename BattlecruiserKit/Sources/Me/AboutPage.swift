import SwiftUI
import DesignSystem

/// Who we are and what we want from you, in the web's words. The sources at
/// the end are a licence condition (ODbL, OGL, CC BY-SA), not a colophon: do
/// not trim them to tidy the page.
struct AboutPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.xl) {
                VStack(alignment: .leading, spacing: Metrics.s) {
                    Text("We love pubs. Proper ones.").font(Typography.rowTitle).foregroundStyle(Palette.ink)
                    Text("Which pub is good, which one is shit, who still serves at midnight. All of it is word of mouth, and all of it changes. This is us trying to write it down before it gets lost.")
                }
                section("Our bias, declared",
                        "Corpopubs. The identikit gastro barns, same font, same small plates, same £8.40 pint. There is a time and a place, and sometimes that place is a Wednesday with your mum. It is just not what should be scoring highly on here.",
                        "What we are after: independent, a bit weird, a bit sticky, somebody behind the bar who is there most days. Obviously that is our opinion. The ratings are yours, so rate accordingly.")
                section("It only works if you chip in",
                        "Everything in here came from someone who was actually in the pub. If something is wrong or missing, hit Fix on any pub and put it right. You get points, there is a leaderboard, and yes we all take it very seriously.")
                section("The Guinness Index",
                        "Nearly every pub pours it, everyone knows roughly what it should cost, so it is a decent shorthand for whether a place is taking the piss. We know some of you are precious about Guinness. That is fine. Cheapest pint might happen one day but that opens a whole can of worms and I can't really be fucked, so not yet.")
                section("Coming", "Crawls, saving pubs to lists. Shout if you want something else.")
                section("House rules", "Be normal. Any racist, homophobic or otherwise dickhead shit and you are gone, straight away, no discussion.")
                section("Who we are", "A few of us who like pubs. No company, no investors, nobody is making money out of this, (currently losing it atm). Got an idea, or fancy helping? Message us. (please I'm begging you)")
                DataSources()
            }
            .font(Typography.body)
            .foregroundStyle(Palette.inkMuted)
            .padding(Metrics.l)
        }
        .background(Palette.canvas)
        .navigationTitle("About")
    }

    private func section(_ title: String, _ paragraphs: String...) -> some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            SectionHeader(title)
            ForEach(paragraphs, id: \.self) { Text($0) }
        }
    }
}
