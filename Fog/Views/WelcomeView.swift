//
//  WelcomeView.swift
//  Fog
//
//  Created by Akshat  Saladi on 3/7/26.
//

import SwiftUI
import SwiftData

// MARK: - Typed Text

private struct TypedText: View {
    let fullText: String
    @State private var displayed: String = ""
    @State private var isDone: Bool = false
    private let speed: Double = 0.03
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text(displayed)
                .multilineTextAlignment(.leading)
            if !isDone {
                BlinkingCursor()
            }
        }
        .onAppear {
            displayed = ""
            isDone = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                typeNext(index: fullText.startIndex)
            }
        }
    }
    
    private func typeNext(index: String.Index) {
        guard index < fullText.endIndex else { isDone = true; return }
        DispatchQueue.main.asyncAfter(deadline: .now() + speed) {
            displayed.append(fullText[index])
            typeNext(index: fullText.index(after: index))
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    var onComplete: () -> Void
    
    @Environment(\.modelContext) private var context
    @Environment(PileManager.self) private var pileManager
    
    // Pile name entered during onboarding
    @State private var pileName: String = "Personal"
    
    // Per-pile theme (written to the Pile on completion)
    @State private var accentColor: Color = .primary
    @State private var useFullTint: Bool = false
    @State private var meshOpacityScale: Double = 1.0
    @State private var rainbowRave: Bool = false
    
    // Steps:
    // 0 — pile card
    // 1 — theme card (pile gone)
    // 2 — feature card: Auto Name (theme gone)
    // 3 — feature card: Auto Group
    // 4 — feature card: Cloud Groups
    // 5 — privacy panel (feature cards gone)
    // 6 — done
    @State private var showPile:    Bool = true
    @State private var showTheme:   Bool = false
    @State private var showCard0:   Bool = false
    @State private var showCard1:   Bool = false
    @State private var showCard2:   Bool = false
    @State private var showPrivacy: Bool = false
    @State private var step:        Int  = 0
    
    @Namespace private var namespace
    
    private let glassShape = RoundedRectangle(cornerRadius: 34, style: .continuous)
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradientBackground()
                
                ScrollView {
                    VStack {
                        GlassEffectContainer(spacing: 16) {
                            VStack(spacing: 16) {
                                
                                if showPile {
                                    pileCard
                                        .glassEffect(.clear.interactive(), in: glassShape)
                                        .glassEffectID("pile", in: namespace)
                                        .glassEffectTransition(.matchedGeometry)
                                }
                                
                                if showTheme {
                                    themeCard
                                        .glassEffect(.clear.interactive(), in: glassShape)
                                        .glassEffectID("theme", in: namespace)
                                        .glassEffectTransition(.matchedGeometry)
                                }
                                
                                if showCard0 {
                                    featureCard(
                                        icon: "textformat.characters",
                                        title: "Auto Name",
                                        description: "AI reads your canvas and suggests a smart title so you never stare at \"Untitled\" again."
                                    )
                                    .glassEffect(.clear.interactive(), in: glassShape)
                                    .glassEffectID("card0", in: namespace)
                                    .glassEffectTransition(.matchedGeometry)
                                }
                                
                                if showCard1 {
                                    featureCard(
                                        icon: "cloud",
                                        title: "Auto Group",
                                        description: "Related canvases are automatically gathered into clouds with AI-written summaries."
                                    )
                                    .glassEffect(.clear.interactive(), in: glassShape)
                                    .glassEffectID("card1", in: namespace)
                                    .glassEffectTransition(.matchedGeometry)
                                }
                                
                                if showCard2 {
                                    featureCard(
                                        icon: "smoke",
                                        title: "Cloud Groups",
                                        description: "Clouds organise themselves into higher-level groups so your ideas stay structured at every scale."
                                    )
                                    .glassEffect(.clear.interactive(), in: glassShape)
                                    .glassEffectID("card2", in: namespace)
                                    .glassEffectTransition(.matchedGeometry)
                                }
                                
                                if showPrivacy {
                                    privacyPanel
                                        .glassEffect(.clear.interactive(), in: glassShape)
                                        .glassEffectID("privacy", in: namespace)
                                        .glassEffectTransition(.matchedGeometry)
                                }
                            }
                            .padding(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TypedText(fullText: navTitle)
                        .font(.title)
                        .id(navTitle)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    if step >= 5 {
                        Button("Get Started") {
                            let trimmed = pileName.trimmingCharacters(in: .whitespacesAndNewlines)
                            let name = trimmed.isEmpty ? "Personal" : trimmed
                            let pile = Pile(name: name, isDefault: true)
                            pile.accentColor = accentColor
                            pile.useFullTint = useFullTint
                            pile.meshOpacityScale = meshOpacityScale
                            pile.rainbowRave = rainbowRave
                            context.insert(pile)
                            try? context.save()
                            pileManager.switchTo(pile)
                            onComplete()
                        }
                        .buttonStyle(.glassProminent)
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                step += 1
                                switch step {
                                case 1:
                                    showPile = false
                                    showTheme = true
                                case 2:
                                    showTheme = false
                                    showCard0 = true
                                case 3:
                                    showCard1 = true
                                case 4:
                                    showCard2 = true
                                case 5:
                                    showCard0 = false
                                    showCard1 = false
                                    showCard2 = false
                                    showPrivacy = true
                                default:
                                    break
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.glassProminent)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var navTitle: String {
        switch step {
        case 0:      return "Welcome to Fog"
        case 1:      return "Make It Yours"
        case 2...4:  return "What Fog Can Do"
        default:     return "How Fog Works"
        }
    }
    
    // MARK: - Pile Card
    
    private var pileCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Your First Pile", systemImage: "square.stack.3d.up.fill")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
            // What is a Pile?
            HStack(alignment: .top, spacing: 16) {
                
                Text("A Pile is your own space — like a profile or workspace. Each Pile has its own canvases, clouds, and theme. Switch between Piles to keep work, personal, and creative projects completely separate.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            
            Divider()
                .padding(.horizontal, 20)
            
            VStack(alignment: .leading) {
                
                TextField("e.g. Personal", text: $pileName)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }
    
    // MARK: - Theme Card
    
    private var themeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Appearance", systemImage: "paintpalette.fill")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
            HStack {
                Text("Accent Color")
                Spacer()
                ColorPicker("", selection: $accentColor, supportsOpacity: false)
                    .labelsHidden()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            
            Toggle("Apply as Tint Color?", isOn: $useFullTint)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Background Intensity")
                        .foregroundStyle(rainbowRave ? .secondary : .primary)
                    Spacer()
                    Text(String(format: "%.0f%%", meshOpacityScale * 100))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $meshOpacityScale, in: 0...2, step: 0.05) {
                    Text("Background Gradient Intensity")
                } minimumValueLabel: {
                    Image(systemName: "sun.min")
                } maximumValueLabel: {
                    Image(systemName: "sun.max")
                }
                .disabled(rainbowRave)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            
            Toggle("Rainbow Rave", isOn: $rainbowRave)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
        }
    }
    
    // MARK: - Feature Card
    
    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(accentColor)
                .frame(width: 52, height: 52)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                TypedText(fullText: description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Privacy Panel
    
    private var privacyPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Privacy", systemImage: "lock.shield.fill")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
            
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "cpu")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("On-Device AI")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("Fog uses Apple's on-device Foundation Models. Your canvases are never sent to a server and everything works offline.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Stored on Your Device")
                        .font(.subheadline).fontWeight(.semibold)
                    Text("All canvases and clouds are saved locally using SwiftData. Nothing leaves your device unless you choose to share it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    WelcomeView(onComplete: {})
        .environment(PileManager())
        .modelContainer(for: Pile.self, inMemory: true)
}
