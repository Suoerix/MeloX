#if canImport(UIKit)
import SwiftUI
import LyricsCore

/// Hosts `LyricsView` in SwiftUI. Read position from `clock` each frame to keep
/// periodic playback updates out of SwiftUI.
public struct LyricsHost: UIViewRepresentable {
    public var document: LyricsDocument
    public var specs: LyricsSpecs
    /// Playback rate; 0 pauses the display link after two seconds.
    public var rate: Double
    public var color: Color
    public var timeOffset: TimeInterval
    public var scrubTime: TimeInterval?
    public var alignment: NSTextAlignment = .left
    public var clock: () -> (time: TimeInterval, rate: Double)
    public var onSeek: (TimeInterval) -> Void
    public var onUserScrollingChanged: ((Bool) -> Void)? = nil

    public init(
        document: LyricsDocument,
        specs: LyricsSpecs,
        rate: Double,
        color: Color,
        timeOffset: TimeInterval,
        scrubTime: TimeInterval?,
        alignment: NSTextAlignment = .left,
        clock: @escaping () -> (time: TimeInterval, rate: Double),
        onSeek: @escaping (TimeInterval) -> Void,
        onUserScrollingChanged: ((Bool) -> Void)? = nil
    ) {
        self.document = document
        self.specs = specs
        self.rate = rate
        self.color = color
        self.timeOffset = timeOffset
        self.scrubTime = scrubTime
        self.alignment = alignment
        self.clock = clock
        self.onSeek = onSeek
        self.onUserScrollingChanged = onUserScrollingChanged
    }

    public func makeUIView(context: Context) -> LyricsView {
        let view = LyricsView(frame: .zero)
        view.timeSource = clock
        view.timeOffset = timeOffset
        view.document = document
        view.specs = specs
        view.tint = UIColor(color)
        view.textAlignment = alignment
        view.onSeek = onSeek
        view.onUserScrollingChanged = onUserScrollingChanged
        return view
    }

    public func updateUIView(_ view: LyricsView, context: Context) {
        if view.document != document { view.document = document }
        if view.specs != specs { view.specs = specs }
        let tint = UIColor(color)
        if view.tint != tint { view.tint = tint }
        if view.textAlignment != alignment { view.textAlignment = alignment }
        view.timeOffset = timeOffset
        view.timeSource = clock
        view.onSeek = onSeek
        view.onUserScrollingChanged = onUserScrollingChanged
        // Before the clock sample: a drag that just ended must leave tracking mode first.
        if scrubTime != nil || view.isScrubbing { view.scrub(to: scrubTime) }
        let sample = clock()
        view.update(time: sample.time, rate: sample.rate)
    }
}
#else
import AppKit
import SwiftUI
import LyricsCore

public struct LyricsHost: NSViewRepresentable {
    public var document: LyricsDocument
    public var specs: LyricsSpecs
    public var rate: Double
    public var color: Color
    public var timeOffset: TimeInterval
    public var scrubTime: TimeInterval?
    public var alignment: NSTextAlignment = .left
    public var clock: () -> (time: TimeInterval, rate: Double)
    public var onSeek: (TimeInterval) -> Void
    public var onUserScrollingChanged: ((Bool) -> Void)? = nil

    public init(
        document: LyricsDocument,
        specs: LyricsSpecs,
        rate: Double,
        color: Color,
        timeOffset: TimeInterval,
        scrubTime: TimeInterval?,
        alignment: NSTextAlignment = .left,
        clock: @escaping () -> (time: TimeInterval, rate: Double),
        onSeek: @escaping (TimeInterval) -> Void,
        onUserScrollingChanged: ((Bool) -> Void)? = nil
    ) {
        self.document = document
        self.specs = specs
        self.rate = rate
        self.color = color
        self.timeOffset = timeOffset
        self.scrubTime = scrubTime
        self.alignment = alignment
        self.clock = clock
        self.onSeek = onSeek
        self.onUserScrollingChanged = onUserScrollingChanged
    }

    public func makeNSView(context: Context) -> LyricsView {
        let view = LyricsView(frame: .zero)
        view.timeSource = clock
        view.timeOffset = timeOffset
        view.document = document
        view.specs = specs
        view.tint = NSColor(color)
        view.textAlignment = alignment
        view.onSeek = onSeek
        view.onUserScrollingChanged = onUserScrollingChanged
        return view
    }

    public func updateNSView(_ view: LyricsView, context: Context) {
        if view.document != document { view.document = document }
        if view.specs != specs { view.specs = specs }
        let tint = NSColor(color)
        if view.tint != tint { view.tint = tint }
        if view.textAlignment != alignment { view.textAlignment = alignment }
        view.timeOffset = timeOffset
        view.timeSource = clock
        view.onSeek = onSeek
        view.onUserScrollingChanged = onUserScrollingChanged
        if scrubTime != nil || view.isScrubbing { view.scrub(to: scrubTime) }
        let sample = clock()
        view.update(time: sample.time, rate: sample.rate)
    }
}
#endif
