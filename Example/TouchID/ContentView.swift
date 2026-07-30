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
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .background {
            Color(.screenBackground)
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

// MARK: - Sections -

private extension ContentView {

    var header: some View {
        Image(.banner)
            .resizable()
            .scaledToFit()
            .frame(height: Metrics.bannerHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.top, Metrics.bannerTopPadding)
            .padding(.bottom, Metrics.bannerBottomPadding)
    }

    var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            result
            Spacer(minLength: Metrics.resultToActionsSpacing)
            actions
            footer
        }
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    var result: some View {
        VStack(alignment: .leading, spacing: Metrics.resultSpacing) {
            Text("RESULT")
                .font(.system(size: Metrics.captionSize, weight: .bold))
                .tracking(Metrics.captionTracking)
                .foregroundStyle(.secondary)

            Text(viewModel.result)
                .font(.system(size: Metrics.resultSize, weight: .bold))
        }
        .padding(.top, Metrics.resultTopPadding)
    }

    var actions: some View {
        VStack(spacing: Metrics.actionsToResetSpacing) {
            VStack(spacing: Metrics.actionSpacing) {
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

            ActionButton(title: "Reset everything", style: .outlined) {
                viewModel.resetTapped()
            }
        }
    }

    var footer: some View {
        HStack(spacing: Metrics.footerSpacing) {
            Text("BUILT BY")
                .font(.system(size: Metrics.footerSize, weight: .bold))
                .tracking(Metrics.captionTracking)
                .foregroundStyle(.secondary)

            Image(.infinumLogo)
                .resizable()
                .scaledToFit()
                .frame(height: Metrics.logoHeight)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Metrics.footerTopPadding)
        .padding(.bottom, Metrics.footerBottomPadding)
    }
}

// MARK: - Metrics -

private enum Metrics {

    static let horizontalPadding: CGFloat = 20

    static let bannerHeight: CGFloat = 48
    static let bannerTopPadding: CGFloat = 8
    static let bannerBottomPadding: CGFloat = 8

    static let captionSize: CGFloat = 11
    static let captionTracking: CGFloat = 1

    static let resultSize: CGFloat = 22
    static let resultSpacing: CGFloat = 8
    static let resultTopPadding: CGFloat = 24
    static let resultToActionsSpacing: CGFloat = 24

    static let actionSpacing: CGFloat = 16
    static let actionsToResetSpacing: CGFloat = 32

    static let footerSize: CGFloat = 10
    static let footerSpacing: CGFloat = 6
    static let footerTopPadding: CGFloat = 24
    static let footerBottomPadding: CGFloat = 0
    static let logoHeight: CGFloat = 11
}

// MARK: - Preview -

#Preview("Light") {
    ContentView()
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
