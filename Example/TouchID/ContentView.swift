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
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                ActionButton(title: "Store some secret") {
                    Task { await viewModel.storeTapped() }
                }

                ActionButton(title: "Store custom secret") {
                    viewModel.storeCustomTapped()
                }

                ActionButton(title: "Read stored secret") {
                    Task { await viewModel.readTapped() }
                }
            }

            Text(viewModel.result)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            ActionButton(title: "Reset everything", role: .destructive) {
                viewModel.resetTapped()
            }
            .padding(.bottom, 20)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .background {
            Color(.secondarySystemBackground)
                .ignoresSafeArea()
        }
        .alert("Store custom secret", isPresented: $viewModel.isCustomSecretAlertPresented) {
            TextField(ContentViewModel.customSecretPlaceholder, text: $viewModel.customSecret)

            Button("Confirm") {
                Task { await viewModel.confirmCustomSecretTapped() }
            }

            Button("Cancel", role: .cancel) {
                viewModel.cancelCustomSecretTapped()
            }
        }
    }
}

// MARK: - Preview -

#Preview {
    ContentView()
}
