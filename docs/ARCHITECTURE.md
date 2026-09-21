# Architecture

## Scoring

`DartBoard.score_mm(x, y)` is the only scorer. Origin is the bull. +Y is 12 o'clock (20). +X is 3 o'clock (6). Angle increases clockwise.

WDF radii in millimetres:

- Double bull `r < 6.35` → 50
- Outer bull `r < 15.9` → 25
- Triple `99 ≤ r < 107`
- Double `162 ≤ r < 170`
- Miss `r ≥ 170`

Exact clockwise sector rays (`angle + 9` divisible by 18) belong to the next sector.

## Rules

`DartEngine.apply_hit` is the only mutator. 501/301 are double-out. Cricket uses 20–15 and bull. Around the Clock needs 1–20 then bull. Practice never ends.

Checkout suggestions come from `CheckoutBook` (exhaustive double-out search). The HUD may show them; the AI may aim at the first dart. Neither writes a different score than `score_mm`.

## Throw

The 3D dart is cinematic. The recorded hit is the intended millimetre coordinate after aim noise. Embedding and misses (drop to the floor) do not re-score.

## Persistence

XDG config/data with `SHADOWFETCH_DARTS_CONFIG` and `SHADOWFETCH_DARTS_DATA` overrides. Corrupt `settings.json` resets to defaults.
