//
//  OnboardingView.swift
//  Pitchee
//
//  Created by Ryo on 2026/9/13.
//

import SwiftUI

struct OnboardingView: View {
    private enum Page: Int, Hashable, CaseIterable {
        case welcome = 0
        case preferences = 1
    }

    private let onFinished: () -> Void

    @State private var navigationPath: [Page] = []
    @State private var selectedVoice: VoicePreference?

    @AppStorage(AppStorageKey.voicePreference) private var savedVoicePreference = ""

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            NavigationStack(path: $navigationPath) {
                onboardingContent(for: .welcome)
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: Page.self) { page in
                        onboardingContent(for: page)
                            .toolbar(.visible, for: .navigationBar)
                            // An empty title here just hides the bar title; verbatim keeps
                            // it out of the string catalog (it is not translatable copy).
                            .navigationTitle(Text(verbatim: ""))
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                if #available(iOS 26.0, *) {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        pageIndicator(for: page)
                                    }
                                    .sharedBackgroundVisibility(.hidden)
                                } else {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        pageIndicator(for: page)
                                    }
                                }
                            }
                    }
            }
        }
    }

    @ViewBuilder
    private func onboardingContent(for page: Page) -> some View {
        VStack(spacing: 0) {
            if page == .welcome {
                header
            }

            ScrollView(showsIndicators: false) {
                Group {
                    switch page {
                    case .welcome:
                        welcomePage
                    case .preferences:
                        preferencesPage
                    }
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 18)
                .id(page)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .scrollBounceBehavior(.basedOnSize)

            footer(for: page)
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Image("PitcheeOnboardingIcon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text("common.brand.wordmark")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(1.8)
            }

            Spacer()

            pageIndicator(for: .welcome)
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private func pageIndicator(for page: Page) -> some View {
        HStack(spacing: 6) {
            ForEach(Page.welcome.rawValue...Page.preferences.rawValue, id: \.self) { index in
                Capsule()
                    .fill(index == page.rawValue ? Color.primary : Color.primary.opacity(0.12))
                    .frame(width: index == page.rawValue ? 24 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.2), value: page)
            }
        }
        .accessibilityElement(children: .ignore)
        // Both the current page and the total are passed in, so translators can
        // reorder them and the label stays correct if the flow gains a page.
        .accessibilityLabel("onboarding.pagination.pageIndicator.a11y \(page.rawValue + 1) \(Page.allCases.count)")
    }

    private var welcomePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 18)

            VStack(alignment: .leading, spacing: 14) {
                Text("onboarding.welcome.title")
                    .font(.system(size: 43, weight: .bold, design: .rounded))
                    .tracking(-1.2)
                    .lineSpacing(-2)
                    .foregroundStyle(.primary)

                Text("onboarding.welcome.subtitle")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.56))
                    .lineSpacing(5)
            }

            welcomeArtwork
                .padding(.vertical, 42)

            VStack(alignment: .leading, spacing: 12) {
                OnboardingFeatureRow(
                    symbol: "waveform.path.ecg",
                    title: String(localized: "onboarding.welcome.featureTrend.title"),
                    detail: String(localized: "onboarding.welcome.featureTrend.description")
                )
                OnboardingFeatureRow(
                    symbol: "lock.shield",
                    title: String(localized: "onboarding.welcome.featurePrivacy.title"),
                    detail: String(localized: "onboarding.welcome.featurePrivacy.description")
                )
            }
        }
    }

    private var welcomeArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(height: 188)

            HStack(spacing: 8) {
                ForEach(Array([38, 74, 118, 58, 94, 142, 66, 108, 48, 86, 128, 54].enumerated()), id: \.offset) { item in
                    Capsule()
                        .fill(item.offset.isMultiple(of: 3) ? Color.primary : Color.primary.opacity(0.24))
                        .frame(width: 7, height: CGFloat(item.element))
                }
            }
            .rotationEffect(.degrees(-4))
            .padding(.horizontal, 24)
        }
        .overlay(alignment: .topTrailing) {
            Text("onboarding.welcome.artworkBadge")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.55))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(uiColor: .systemBackground).opacity(0.8), in: Capsule())
                .padding(16)
        }
        .accessibilityHidden(true)
    }

    private var preferencesPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("onboarding.preferences.title")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.primary)

                Text("onboarding.preferences.subtitle")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.56))
                    .lineSpacing(4)
            }
            .padding(.bottom, 34)

            Text("onboarding.preferences.voicePrompt")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.bottom, 14)

            VStack(spacing: 12) {
                ForEach(VoicePreference.allCases, id: \.self) { option in
                    VoicePreferenceCard(
                        option: option,
                        isSelected: selectedVoice == option
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedVoice = option
                        }
                    }
                }
            }

            PrivacyPromiseView()
                .padding(.top, 34)
        }
    }

    private func footer(for page: Page) -> some View {
        VStack(spacing: 12) {
            Button {
                advance(from: page)
            } label: {
                HStack(spacing: 10) {
                    Text(page == .welcome
                        ? String(localized: "onboarding.footer.startSetup")
                        : String(localized: "onboarding.footer.finishSetup"))
                    Image(systemName: page == .welcome ? "arrow.right" : "checkmark")
                        .font(.system(size: 14, weight: .bold))
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .frame(maxWidth: 520)
            }
            .modifier(LiquidGlassProminentButtonStyleModifier())
            .controlSize(.large)
            .disabled(!canAdvance(for: page))
            .accessibilityHint(page == .preferences && !canAdvance(for: page)
                ? String(localized: "onboarding.footer.voiceSelectionRequired.a11y")
                : "")
        }
        .frame(maxWidth: 520)
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private func canAdvance(for page: Page) -> Bool {
        page == .welcome || selectedVoice != nil
    }

    private func advance(from page: Page) {
        guard canAdvance(for: page) else { return }

        switch page {
        case .welcome:
            navigationPath.append(.preferences)
        case .preferences:
            guard let selectedVoice else { return }
            savedVoicePreference = selectedVoice.rawValue
            onFinished()
        }
    }
}

private struct LiquidGlassProminentButtonStyleModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

private struct OnboardingFeatureRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 34, height: 34)
                .foregroundStyle(.primary)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.5))
            }
        }
    }
}

#if DEBUG
private extension OnboardingView {
    init(previewingPreferences: Bool) {
        onFinished = {}
        _navigationPath = State(initialValue: previewingPreferences ? [.preferences] : [])
        _selectedVoice = State(initialValue: .feminine)
    }
}

#Preview("Debug - Welcome") {
    OnboardingView(onFinished: {})
        .defaultAppStorage(DebugPreviewDefaults.store)
}

#Preview("Debug - Voice Preference") {
    OnboardingView(previewingPreferences: true)
        .defaultAppStorage(DebugPreviewDefaults.store)
}
#endif
