import SwiftUI
import AppEnvironment
import DesignSystem
import PubDBClient
import PubDBModels

/// "Report": the reasons the server offers for this kind of thing, one tap,
/// then "Reported, thanks". A report takes nothing down by itself.
struct ReportSheet: View {
    let target: ReportTarget
    let context: PanelContext

    @State private var sent = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.m) {
            Text("Report").font(Typography.title).foregroundStyle(Palette.ink)
            if sent {
                Text("Reported, thanks. We'll take a look.").font(Typography.body).foregroundStyle(Palette.good)
                Button("Done") { dismiss() }.buttonStyle(ChipStyle(isSelected: true))
            } else {
                ForEach(reasons) { reason in
                    Button(reason.label) { send(reason) }
                        .buttonStyle(ChipStyle())
                }
                if let error {
                    Text(error).font(Typography.secondary).foregroundStyle(Palette.bad)
                }
                Button("Cancel") { dismiss() }.foregroundStyle(Palette.inkMuted)
            }
        }
        .padding(Metrics.xl)
        .presentationDetents([.medium])
    }

    private var reasons: [ReportReason] {
        (context.meta?.reportReasons ?? []).filter { $0.applies(to: target.type) }
    }

    private func send(_ reason: ReportReason) {
        Task {
            do {
                _ = try await context.writer.sendReport(type: target.type, id: target.id, reason: reason.key)
                sent = true
            } catch {
                self.error = PubDBError.wrapping(error)?.userMessage
            }
        }
    }
}
