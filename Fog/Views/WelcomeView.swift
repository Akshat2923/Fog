//
//  WelcomeView.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/7/26.
//

import SwiftUI

struct WelcomeView: View {
    var onComplete: () -> Void

    @AppStorage("accentColor") private var accentColor: Color = .primary
    @AppStorage("useFullTint") private var useFullTint: Bool = false
    @AppStorage("meshOpacityScale") private var meshOpacityScale: Double = 1.0
    @AppStorage("rainbowRave") private var rainbowRave: Bool = false

    private let featureSlides: [(icon: String, title: String, subtitle: String)] = [
        ("text.badge.plus", "Auto Name", "AI suggests titles from your content"),
        ("cloud.fill", "Auto Group", "Related canvases become clouds with summaries"),
        ("square.3.layers.3d", "Cloud Groups", "Clouds organize intelligently into groups")
    ]

    var body: some View {
        ZStack {
            MeshGradientBackground()

            ScrollView(.horizontal) {
                LazyHStack(spacing: 24) {
                    ForEach(Array(featureSlides.enumerated()), id: \.offset) { _, slide in
                        featureSlide(icon: slide.icon, title: slide.title, subtitle: slide.subtitle)
                    }

                    appearanceSlide
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 40)
            .scrollTargetBehavior(.paging)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }

    private func featureSlide(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 120))
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(maxHeight: 320)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title.weight(.semibold))
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(minWidth: 340, maxWidth: 400)
        .scrollTransition(axis: .horizontal) { content, phase in
            content.offset(x: phase.value * -250)
        }
        .containerRelativeFrame(.horizontal)
        .clipShape(RoundedRectangle(cornerRadius: 40))
    }

    private var appearanceSlide: some View {
        VStack(spacing: 24) {
            Text("Customize Appearance")
                .font(.title.weight(.semibold))

            List {
                Section(header: Text("Appearance")) {
                    ColorPicker("Accent Color", selection: $accentColor)
                    Toggle("Apply as Tint Color?", isOn: $useFullTint)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Background Intensity")
                                .foregroundStyle(rainbowRave ? .secondary : .primary)
                            Spacer()
                            Text(String(format: "%.0f%%", meshOpacityScale * 100))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .accessibilityHidden(true)
                        }
                        Slider(value: $meshOpacityScale, in: 0...2, step: 0.05) {
                            Text("Background Gradient Intensity")
                        } minimumValueLabel: {
                            Image(systemName: "sun.min")
                        } maximumValueLabel: {
                            Image(systemName: "sun.max")
                        }
                        .disabled(rainbowRave)
                        .accessibilityLabel("Background intensity")
                    }
                    Toggle("Rainbow Rave", isOn: $rainbowRave)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .frame(height: 280)

            Button("Get Started") {
                onComplete()
            }
            .buttonStyle(.glassProminent)
        }
        .padding(32)
        .frame(minWidth: 360, maxWidth: 420)
        .scrollTransition(axis: .horizontal) { content, phase in
            content.offset(x: phase.value * -250)
        }
        .containerRelativeFrame(.horizontal)
        .clipShape(RoundedRectangle(cornerRadius: 40))
    }
}

#Preview {
    WelcomeView(onComplete: {})
}
