# App icon — Mixtape Pocket

Colors are design-system tokens only (see design/tokens.json).

| Mode | Background | Pocket | Stitch | Cassette window | Reels | Tape |
|---|---|---|---|---|---|---|
| Light (default) | #E6E7E9 | #2C2F33 | #9AA0A6 | #D5DDC8 | #FF6A13 | #26301F |
| Dark | #16181A | #F3F4F5 | #5E646A | #2C2F33 | #FF6A13 | #D5DDC8 |
| Tinted (grayscale) | #000000 | #E6E7E9 | #5E646A | #2C2F33 | #FFFFFF | #9AA0A6 |

## Files
- `AppIcon.appiconset/` — Xcode single-size icon set with Light / Dark / Tinted appearances (Xcode 16+, iOS 18+ shows dark & tinted; older iOS uses Light).
- `png/light|dark|tinted/` — every legacy size, named like Flutter's default `ios/Runner/Assets.xcassets/AppIcon.appiconset` (drop-in replacement for the light set).
- `svg/` — vector masters (1024 grid). PNGs are square and opaque (no alpha, no rounded corners — iOS applies the mask).

## Install
Replace `ios/Runner/Assets.xcassets/AppIcon.appiconset` with `AppIcon.appiconset` from this folder, then build in Xcode.
