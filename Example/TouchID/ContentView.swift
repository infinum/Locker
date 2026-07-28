//
//  ContentView.swift
//  TouchID
//
//  Copyright © 2026 Infinum Ltd. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Private properties -

    @State private var viewModel = ContentViewModel()

    // MARK: - Body -

    var body: some View {
        VStack(spacing: 12) {
            Button("Reset everything", role: .destructive) {
                viewModel.resetTapped()
            }

            Button("Store some secret") {
                Task { await viewModel.storeTapped() }
            }

            Text(viewModel.storeResult)

            Button("Read stored secret") {
                Task { await viewModel.readTapped() }
            }

            Text(viewModel.readResult)
        }
        .buttonStyle(.bordered)
        .multilineTextAlignment(.center)
        .padding()
    }
}

// MARK: - Preview -

#Preview {
    ContentView()
}
