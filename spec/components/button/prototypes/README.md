# Button prototypes on web and GTK (#26): throwaway

**These are prototypes, not libraries.** They exist to check whether the Button contract
([`../button.spec.yaml`](../button.spec.yaml)) carries over to a native `<button>` and to a stock `GtkButton` without
SwiftUI assumptions (decisions/0002, "Risk"). The findings are in
[`../decisions/0002-portability-to-web-and-gtk.md`](../decisions/0002-portability-to-web-and-gtk.md). The web library
starts in phase 6 (#40) and the GTK library in phase 7; neither starts from these files. Delete this folder when they
do.

| File | What it is |
|---|---|
| `web/index.html` | A static page, no framework and no build step: every variant × role × size, icon + label and icon-only, a state matrix, a width check for loading, live buttons, hit areas |
| `web/button.css` | westron's CSS on a native `<button>` |
| `web/tokens.css` | Generated: the tokens the contract binds, as CSS custom properties in four themes |
| `web/resolve-tokens.swift` | Writes `web/tokens.css` and `gtk/tokens.css` from `tokens/` and the contract's `tokens:` block |
| `web/snapshot.swift` | Renders the page in WebKit to a PNG, or probes the real pseudo-classes and clicks |
| `gtk/button.py` | A GTK 4 + libadwaita window in Python (PyGObject): stock `GtkButton`s with style classes |
| `gtk/button.css` | westron's CSS for those buttons, for GTK 4.20 CSS |
| `gtk/tokens.css` | Generated: the same tokens for GTK CSS |

## Run

From the repository root:

```sh
source tools/apple/xcode-env.sh
swift spec/components/button/prototypes/web/resolve-tokens.swift > spec/components/button/prototypes/web/tokens.css
swift spec/components/button/prototypes/web/resolve-tokens.swift --gtk > spec/components/button/prototypes/gtk/tokens.css

open spec/components/button/prototypes/web/index.html          # any browser; ?theme=dark-hc forces a theme
swift spec/components/button/prototypes/web/snapshot.swift shot .build/button-prototype/web-light.png
swift spec/components/button/prototypes/web/snapshot.swift shot .build/button-prototype/web-dark.png --dark
swift spec/components/button/prototypes/web/snapshot.swift shot .build/button-prototype/web-dark-hc.png theme=dark-hc
swift spec/components/button/prototypes/web/snapshot.swift probe
```

The GTK prototype has **not been run**: GTK 4, libadwaita and PyGObject were not available where it was written. It
needs GTK 4.20 or later and libadwaita 1.6 or later; then:

```sh
python3 spec/components/button/prototypes/gtk/button.py
python3 spec/components/button/prototypes/gtk/button.py --dark --screenshot .build/button-prototype/gtk-dark.png
```
