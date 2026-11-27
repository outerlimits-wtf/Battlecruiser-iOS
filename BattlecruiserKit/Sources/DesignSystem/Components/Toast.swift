import SwiftUI

/// A short message that slides up from the bottom and goes after four seconds:
/// "Saved. The next person through the door gets that."
public struct ToastMessage: Equatable, Sendable {
    public enum Tone: Sendable {
        case good
        case bad
    }

    public var text: String
    public var tone: Tone

    public init(_ text: String, tone: Tone = .good) {
        self.text = text
        self.tone = tone
    }
}

extension View {
    /// Shows `message` at the bottom while it is non-nil, and clears it after four seconds.
    public func toast(_ message: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: ToastMessage?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                Text(message.text)
                    .font(Typography.body)
                    .foregroundStyle(message.tone == .good ? Palette.good : Palette.bad)
                    .padding(Metrics.m)
                    .frame(maxWidth: .infinity)
                    .background(message.tone == .good ? Palette.goodSoft : Palette.badSoft,
                                in: RoundedRectangle(cornerRadius: Metrics.cardRadius))
                    .padding(Metrics.l)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .task(id: message) {
                        UIAccessibility.post(notification: .announcement, argument: message.text)
                        try? await Task.sleep(for: .seconds(4))
                        self.message = nil
                    }
            }
        }
        .animation(.easeOut(duration: 0.25), value: message)
    }
}
