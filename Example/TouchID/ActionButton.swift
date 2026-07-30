//
//  ActionButton.swift
//  TouchID
//
//  Copyright © 2026 Infinum Ltd. All rights reserved.
//

import SwiftUI

/// Full width button in one of the two brand styles.
struct ActionButton: View {

    // MARK: - Style -

    enum Style {

        /// Brand red fill with a white title, for the primary actions.
        case filled

        /// Brand red border and title over the screen background, for destructive actions.
        case outlined
    }

    // MARK: - Internal properties -

    let title: String
    var style: Style = .filled
    let action: () -> Void

    // MARK: - Body -

    var body: some View {
        Button(title, action: action)
            .buttonStyle(BrandButtonStyle(style: style))
    }
}

// MARK: - Button style -

private struct BrandButtonStyle: ButtonStyle {

    let style: ActionButton.Style

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: Metrics.titleSize, weight: .bold))
            .foregroundStyle(titleColor)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.height)
            .background(background)
            // The outlined style has no fill, so the whole shape needs to stay tappable.
            .contentShape(.rect(cornerRadius: Metrics.cornerRadius))
            .opacity(configuration.isPressed ? Metrics.pressedOpacity : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

private extension BrandButtonStyle {

    var titleColor: Color {
        switch style {
        case .filled: .white
        case .outlined: Color(.brandRed)
        }
    }

    @ViewBuilder
    var background: some View {
        switch style {
        case .filled:
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .fill(Color(.brandRed))
        case .outlined:
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .strokeBorder(Color(.brandRed), lineWidth: Metrics.borderWidth)
        }
    }
}

// MARK: - Metrics -

private enum Metrics {

    static let titleSize: CGFloat = 17
    static let height: CGFloat = 50
    static let cornerRadius: CGFloat = 4
    static let borderWidth: CGFloat = 2
    static let pressedOpacity: CGFloat = 0.75
}

// MARK: - Preview -

#Preview {
    VStack(spacing: 16) {
        ActionButton(title: "Filled") {}
        ActionButton(title: "Outlined", style: .outlined) {}
    }
    .padding(.horizontal, 20)
}
