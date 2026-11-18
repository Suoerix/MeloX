# StarryLyrics (vendored from StarryPlayer)

This local Swift package is a port of the playing-screen lyrics component of
[StarryPlayer](https://github.com/Mrs4s/StarryPlayer) (directory
`Packages/StarryKit/Sources/LyricsCore` and `Packages/StarryKit/Sources/LyricsUI`),
adapted to run on iOS (UIKit hosting, snapshot-based blur) as well as macOS.

The component provides:

- `LyricsView` — a CADisplayLink-driven Core Animation lyrics view with the
  StarryPlayer animations (additive per-line spring lag, staggered line
  changes, word-synced springs, karaoke sweep, syllable lift, emphasis wave,
  glow, background-vocal expansion, instrumental countdown dots, blur).
- `LyricsCore` — the lyric document model (`LyricsDocument`, `LyricLine`,
  `LyricWord`, `LyricSyllable`), selection state machine and text grouping
  helpers.

## Licensing

The code in this package is Copyright © the StarryPlayer authors and is
distributed under the GNU Affero General Public License v3.0 — see
`LICENSE-StarryPlayer` (the upstream `LICENSE` of the StarryPlayer repository).
It is combined with MeloX (GPL-3.0) under the one-way compatibility between
the AGPL-3.0 and GPL-3.0; the files in this package remain under the AGPL-3.0.

## Local modifications

- `LyricsView` hosts as a `UIView` on iOS (pan/touch gestures instead of
  scroll/mouse events) and an `NSView` on macOS.
- Line blur uses pre-rendered image snapshots on iOS (Core Animation layer
  `filters` are macOS-only); macOS keeps the live CIGaussianBlur filter path.
- `LineSnapshotRenderer` renders through `UIGraphicsImageRenderer` +
  CoreImage on iOS and the original Metal `CARenderer` path on macOS.
- `RubyGroups.decodeTimes` (TTML-only helper) was removed.
