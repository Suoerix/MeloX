import Foundation
import LyricsCore

// The MeloX lyric model (`LyricLine`, `LyricSyllable`, `LyricAgent`) is mapped
// into StarryPlayer's document model (`LyricsCore.LyricsDocument`), which the
// ported `LyricsView` renders.

private typealias StarryLine = LyricsCore.LyricLine
private typealias StarryWord = LyricsCore.LyricWord
private typealias StarrySyllable = LyricsCore.LyricSyllable

@MainActor
enum StarryLyricsDocumentBuilder {

    static func document(
        from lyrics: [LyricLine],
        usesPseudoSyllables: Bool,
        usesDuetLayout: Bool
    ) -> LyricsCore.LyricsDocument {
        var agents: [LyricsCore.LyricAgent] = []
        var agentSeen: Set<String> = []
        func starryAgent(for agent: LyricAgent?) -> LyricsCore.LyricAgent? {
            guard let agent, usesDuetLayout else { return nil }
            if agentSeen.insert(agent.identifier).inserted {
                agents.append(
                    LyricsCore.LyricAgent(
                        id: agent.identifier,
                        kind: agent.kind == .group ? .group : .person,
                        names: [.init(agent.displayName)]
                    )
                )
            }
            return agents.first { $0.id == agent.identifier }
        }

        var lines: [StarryLine] = []
        for (index, line) in lyrics.enumerated() {
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            let next = lyrics[(index + 1)...].first {
                !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            let primaryStart = line.time
            let primaryEnd: TimeInterval
            if let duration = line.duration, duration > 0 {
                primaryEnd = line.time + duration
            } else if let next {
                primaryEnd = max(line.time + 0.1, next.time)
            } else {
                primaryEnd = line.time + 5
            }

            // Words: timed syllables grouped by tokenizer; LRC lines stay one
            // word (or per-character pseudo timing when enabled).
            var syllables = line.syllables.map(starrySyllable)
            if syllables.isEmpty, usesPseudoSyllables {
                syllables = line.makePseudoSyllables().map(starrySyllable)
            }
            let words = syllables.isEmpty
                ? [StarryWord(start: primaryStart, end: primaryEnd, text: line.text)]
                : LyricWordGrouping.words(from: syllables)

            var romanizationWords: [StarryWord]?
            if !line.romanizationSyllables.isEmpty {
                romanizationWords = LyricWordGrouping.words(
                    from: line.romanizationSyllables.map(starrySyllable)
                )
            }

            var background: LyricsCore.LyricBackgroundVocals?
            if let vocal = line.backgroundVocal {
                let vocalText = vocal.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !vocalText.isEmpty {
                    let vocalEnd: TimeInterval
                    if let duration = vocal.duration, duration > 0 {
                        vocalEnd = vocal.time + duration
                    } else {
                        vocalEnd = primaryEnd
                    }
                    let vocalSyllables = vocal.syllables.map(starrySyllable)
                    let vocalWords = vocalSyllables.isEmpty
                        ? [StarryWord(start: vocal.time, end: vocalEnd, text: vocal.text)]
                        : LyricWordGrouping.words(from: vocalSyllables)
                    background = LyricsCore.LyricBackgroundVocals(
                        start: vocal.time,
                        end: vocalEnd,
                        words: vocalWords,
                        translation: vocal.translation,
                        romanization: nil,
                        romanizationWords: nil,
                        agentIDs: starryAgent(for: line.agent).map { [$0.id] } ?? []
                    )
                }
            }

            let starryAgentRef = starryAgent(for: line.agent)
            let start = [primaryStart, background?.start].compactMap { $0 }.min() ?? primaryStart
            let end = [primaryEnd, background?.end].compactMap { $0 }.max() ?? primaryEnd
            lines.append(
                StarryLine(
                    id: index,
                    start: start,
                    end: end,
                    words: words,
                    translation: line.translation,
                    romanization: line.romanization,
                    romanizationWords: romanizationWords,
                    singer: line.agent?.alignment == .flipped ? .secondary : .primary,
                    background: background,
                    primaryStart: primaryStart,
                    primaryEnd: primaryEnd,
                    isParagraphStart: false,
                    agentIDs: starryAgentRef.map { [$0.id] } ?? []
                )
            )
        }

        var document = LyricsCore.LyricsDocument(
            format: lines.contains { !$0.syllables.isEmpty } ? .ttml : .lrc,
            lines: lines,
            metadata: [:],
            agents: agents
        )
        // Derive timed romanization for lines whose sources only carry plain
        // romanization text, exactly as StarryPlayer does for TTML imports.
        // (Qualified: MeloX ships its own same-named aligner in Core/Lyrics.)
        LyricsCore.LyricRomanizationAligner.alignMissing(in: &document)
        return document
    }

    private static func starrySyllable(_ syllable: LyricSyllable) -> StarrySyllable {
        StarrySyllable(
            start: syllable.startTime,
            end: syllable.endTime,
            text: syllable.text
        )
    }
}
