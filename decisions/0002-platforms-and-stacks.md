# 0002. Platforms and stacks

Date: 2026-11-14. Status: accepted for Apple and Linux; provisional for web and Android.

## Decision

| Platform | Stack | Status |
|---|---|---|
| Apple (iOS, iPadOS, macOS, watchOS) | SwiftUI, one SwiftPM package | Pilot platform |
| Linux | GTK4 + libadwaita in Rust; the main audience is GNOME | Accepted |
| Web | CSS custom properties; Web Components in Lit or styles on top of native elements | To be settled in the web phase |
| Android | Compose on top of Material3 through `CompositionLocal` | Later |

## Pilot

Components appear in SwiftUI first. Web and Linux get them from the same contracts once the pipeline has been worked out on Apple.

Risk: the contract may quietly take on SwiftUI assumptions. To catch this early, the Button contract is checked with a short prototype on web and GTK before components are released in bulk.

## Consequences

- On Apple, Liquid Glass and the HIG apply: the brand lives in the content layer, and the accent color is used sparingly.
- On GNOME the room for the brand is narrow: the accent color, a small `style.css`, icons, heading typography. High contrast cannot be turned off.
- watchOS gets a deliberately reduced subset of components.
