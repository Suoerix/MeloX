import SwiftUI
import LyricsCore
import LyricsUI

/// The playing-screen lyrics page, rendered by the StarryPlayer lyrics
/// component (`LyricsView`, a CADisplayLink-driven Core Animation view) hosted
/// through `LyricsHost`. All animation behaviour — the additive per-line spring
/// lag with staggered delays, word-synced line-change springs, the karaoke
/// sweep with its gradient feather, syllable lift, the emphasis wave with glow,
/// blur of inactive lines, background-vocal expansion and instrumental-break
/// countdown dots — is the component's own.
struct StarryLyricsScreen: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(PlayerStore.self) private var player
    @Environment(AppSettings.self) private var settings

    let lyrics: [LyricLine]
    let errorMessage: String?
    let isActive: Bool
    /// Whether the player controls are hidden; when they are, the lyrics take
    /// the full height (like the previous Apple-Music-style view).
    let isInterfaceHidden: Bool
    /// Height reserved at the bottom for the player controls while visible.
    let bottomOverlayHeight: CGFloat
    let onInterfaceInteraction: (() -> Void)?
    let onInitialFocusPrepared: (() -> Void)?

    var body: some View {
        GeometryReader { proxy in
            let bottomInset = min(
                max(isInterfaceHidden ? 0 : bottomOverlayHeight, 0),
                max(proxy.size.height - 1, 0)
            )
            ZStack(alignment: .top) {
                if lyrics.isEmpty {
                    emptyState
                } else {
                    // The lyrics viewport ends above the controls, as the previous
                    // Apple-Music-style view's `referenceLyricsViewportHeight` did.
                    let hostHeight = max(proxy.size.height - bottomInset, 1)
                    lyricsHost(height: hostHeight)
                        .frame(height: hostHeight, alignment: .top)
                    if bottomOverlayHeight > 0 {
                        bottomTapTarget(height: bottomInset)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .animation(
                accessibilityReduceMotion ? nil : .smooth(duration: 0.3),
                value: isInterfaceHidden
            )
        }
    }

    private var emptyState: some View {
        Group {
            if let errorMessage {
                ContentUnavailableView(
                    "ui.lyrics.empty",
                    systemImage: "quote.bubble",
                    description: Text(errorMessage)
                )
                .foregroundStyle(.white)
            } else {
                ProgressView("ui.lyrics.loading")
                    .tint(.white)
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .onTapGesture { onInterfaceInteraction?() }
    }

    /// Tapping where the controls would be reveals them, as the previous view's
    /// `hiddenControlsTapTarget` did.
    private func bottomTapTarget(height: CGFloat) -> some View {
        Color.clear
            .contentShape(.rect)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .onTapGesture { onInterfaceInteraction?() }
            .accessibilityHidden(true)
    }

    private func lyricsHost(height: CGFloat) -> some View {
        LyricsHost(
            document: document,
            specs: starrySpecs(),
            rate: player.isPlaying ? 1 : 0,
            color: .white,
            timeOffset: settings.effectiveLyricsAdvanceTime(for: lyrics),
            scrubTime: nil,
            clock: {
                let rate: Double = player.isPlaying ? 1 : 0
                return (player.estimatedProgress(at: .now), rate)
            },
            onSeek: { seconds in
                player.seek(to: seconds)
                onInterfaceInteraction?()
            },
            onUserScrollingChanged: { began in
                if began { onInterfaceInteraction?() }
            }
        )
        // StarryPlayer fades the lyrics pane's top and bottom edges.
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.07),
                    .init(color: .black, location: 0.82),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .onAppear { onInitialFocusPrepared?() }
        .onChange(of: lyrics) { onInitialFocusPrepared?() }
    }

    private var document: LyricsCore.LyricsDocument {
        StarryLyricsDocumentBuilder.document(
            from: lyrics,
            usesPseudoSyllables: settings.lyricsPseudoWordByWord,
            usesDuetLayout: settings.lyricsDuetLayoutEnabled
        )
    }

    /// MeloX's lyric preferences mapped onto the component's specs. Typography
    /// keeps the app's user settings (at `scale` 1, so the font sizes are the
    /// effective points, as before); every animation parameter stays at the
    /// StarryPlayer defaults.
    private func starrySpecs() -> LyricsSpecs {
        var specs = LyricsSpecs.windowed
        let fontSize = CGFloat(settings.lyricsFontSize)
        let ratio = fontSize / specs.fontSize
        specs.fontSize = fontSize
        specs.backgroundVocalsFontSize *= ratio
        specs.translationBackgroundVocalsFontSize *= ratio
        specs.romanizationBackgroundVocalsFontSize *= ratio
        specs.rubyFontSize *= ratio
        specs.rubyBackgroundVocalsFontSize *= ratio
        specs.fontLeading = specs.fontLeading.map { $0 * ratio }
        // Translation and romanization follow the app's own scale settings,
        // as the previous Apple-Music-style view did.
        specs.translationFontSize = fontSize * settings.lyricsTranslationFontScale
        specs.romanizationFontSize = max(
            fontSize * settings.lyricsRomanizationFontScale,
            13
        )
        specs.fontWeight = settings.lyricsFontWeight.uiKitWeight
        if settings.lyricsLineSpacing > 0 {
            specs.lineSpacing = CGFloat(settings.lyricsLineSpacing)
        }
        specs.selectedLinePosition = .topRelative(
            percentage: CGFloat(settings.lyricsFocusPosition * 100)
        )
        specs.perSyllableEnabled = settings.lyricsWordByWord
        specs.glowEnabled = settings.lyricsGlowEnabled
        specs.showTranslation = settings.lyricsTranslationEnabled
        specs.showRomanization = settings.lyricsRomanizationEnabled
        specs.blur.mode = .both
        specs.blur.radius = settings.lyricsBlurIntensity > 0 ? 3 : 0
        specs.blur.maximum = max(specs.blur.radius, 4)
        switch settings.lyricsInterlude.mode {
        case .hidden:
            specs.instrumentalBreakMinimumGap = .infinity
        case .preciseTiming, .automatic:
            specs.instrumentalBreakMinimumGap = max(
                settings.lyricsInterlude.minimumInferredGapDuration,
                3
            )
        }
        return specs
    }
}
