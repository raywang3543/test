# Y2K App Icon Design Spec

**App**: 性格匹配测试 (Personality Match Test)  
**Date**: 2026-04-19  
**Status**: Approved

---

## Concept

**错位叠层双心 (Offset-Overlap Dual Hearts)**

Two hearts stacked with a deliberate offset — a cream/white heart in the foreground (top-left) overlapping a lime-green heart in the background (bottom-right) — set on a hot-pink background. The layered asymmetry creates depth without gradients or shadows, consistent with the app's Neo-Y2K flat aesthetic.

The dual hearts communicate personality matching and compatibility at a glance. The cream + lime-on-pink palette pulls directly from the existing `Y2K` design token set.

---

## Visual Style

**Neo-Y2K Flat** — solid fills, hard ink outlines, zero blur. No gradients, no gloss, no 3D. Matches the app's existing `Y2K` theme tokens exactly.

---

## Color Specification

| Element | Color | Token |
|---|---|---|
| Background | `#FF5EA8` | `Y2K.pink` |
| Foreground heart fill | `#FFF5E1` | `Y2K.bg` |
| Background heart fill | `#C6FF3D` | `Y2K.lime` |
| Stroke / outline | `#0E0E12` | `Y2K.ink` |
| Highlight stroke (on foreground heart) | `#FF5EA8` | `Y2K.pink` |
| Corner decoration glyphs | `#0E0E12` | `Y2K.ink` |

---

## Geometry

### Canvas
- **Size**: 1024 × 1024 px (master SVG)
- **Corner radius**: 230px (≈22.5% of 1024 — renders correctly as iOS/Android adaptive icon)
- **Background**: filled rectangle, full bleed

### Hearts
- Both hearts use the same SVG path scaled to ~70% of canvas width (~716px wide)
- **Foreground heart**: positioned top-left, anchored at `(0, 0)` of the heart bounding box
- **Background heart**: offset `+25%` right and `+25%` down relative to foreground heart (~179px each axis)
- **Stroke width**: 25px at 1024px canvas (scales to 2.5px at 100px render)
- **Highlight stroke**: a single curved stroke on the upper-left lobe of each heart, `opacity: 0.65` (foreground) / `0.50` (background), simulates Y2K sheen without gradients

### Hard-edge shadow on icon container
When rendered as a card/sticker (e.g., in marketing or App Store screenshots):
- `box-shadow: 4px 4px 0 #0E0E12`
- No blur

### Corner decorations
Three small glyphs placed in corners of the canvas to break the symmetry:
| Glyph | Position | Size |
|---|---|---|
| `✦` | Top-left (~10px, 12px) | 12% of canvas (~123px) |
| `✧` | Bottom-right (~14px, 12px) | 9% (~92px) |
| `+` | Top-right (~13px, 13px) | 8% (~82px) |

All glyphs: color `#0E0E12`, `opacity: 0.45 / 0.35 / 0.30` respectively.

---

## Heart Path (SVG)

The heart is constructed as a single cubic-bezier path. Reference path at 72×62 viewport:

```
M36 57C36 57 2 36 2 16C2 8 8 2 17 2C23 2 29 6 36 13C43 6 49 2 55 2C64 2 70 8 70 16C70 36 36 57 36 57Z
```

Scale this path to the required canvas size using `transform="scale(factor)"`.

---

## Output Sizes

| Use | Size | Corner radius | Notes |
|---|---|---|---|
| Android `mipmap-xxxhdpi` | 192×192 | 43px | |
| iOS App Icon | 1024×1024 | 230px | exported as PNG |
| Android adaptive icon foreground | 108×108dp | — | background layer is solid `#FF5EA8` |
| App Store / Play Store | 1024×1024 | 230px | |
| Notification / small icon | 24×24 | — | simplified: single white heart on `#FF5EA8` |
| Favicon | 32×32 | — | simplified: single cream heart on `#FF5EA8` |

---

## Implementation Approach

The icon will be produced as a **Flutter `CustomPainter`** that draws the icon programmatically, plus an export script that renders it to PNG at required sizes using `flutter_launcher_icons`.

### Files to create / modify
1. `assets/icon/app_icon.svg` — master SVG source (hand-written or from CustomPainter export)
2. `pubspec.yaml` — add `flutter_launcher_icons` dev dependency and config
3. Run `flutter pub run flutter_launcher_icons` to generate all platform assets

### Simplified icon for notification/favicon
At sizes ≤ 32px the offset-overlap detail is illegible. Use a single centered cream heart `#FFF5E1` on `#FF5EA8` background with no decorations.

---

## Non-Goals

- No animated icon variant at this time
- No dark-mode icon variant (the pink background reads well on both light and dark home screens)
- No text/wordmark in the icon
