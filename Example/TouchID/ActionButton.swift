//
//  ActionButton.swift
//  TouchID
//
//  Copyright © 2026 Infinum Ltd. All rights reserved.
//

import SwiftUI

/// Full width button with a rounded rectangular border shape, rendered with
/// the Liquid Glass appearance on iOS 26 and later.
struct ActionButton: View {

    // MARK: - Internal properties -

    let title: String
    var role: ButtonRole?
    let action: () -> Void

    // MARK: - Body -

    var body: some View {
        Button(role: role, action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonBorderShape(.roundedRectangle(radius: 12))
        // The glass button styles don't tint a destructive role on their own, unlike the bordered ones.
        .tint(role == .destructive ? Color.red : nil)
        .glassOrBorderedButtonStyle()
    }
}

// MARK: - Button style -

private extension View {

    /// Liquid Glass button appearance on iOS 26 and later, bordered appearance below.
    @ViewBuilder
    func glassOrBorderedButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}

// MARK: - Preview -

#Preview {
    VStack(spacing: 12) {
        ActionButton(title: "Regular") {}
        ActionButton(title: "Destructive", role: .destructive) {}
    }
    .padding(.horizontal, 24)
}
