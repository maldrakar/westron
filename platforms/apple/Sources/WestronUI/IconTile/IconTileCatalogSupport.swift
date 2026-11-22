// Hand-written. CATALOG ONLY: what the westron catalog (WestronCatalog, in this package) needs to draw the alternative
// fill of a list's tile beside the contract's, for the owner to compare in one picture while question 3 of the
// contract's decisions/0001 is open. Everything here is `package`, visible to the targets of this Swift package and
// never to a product that imports WestronUI: it is not public API, and the parity lint (#21) does not see it. It is
// removed with the alternative once the owner chooses.

import SwiftUI

extension EnvironmentValues {
    /// The fill IconTile draws a list's color with. Catalog only: a product never sets it, and the contract's is solid.
    @Entry var iconTileFill: IconTileFill = .solid
}

extension View {
    /// Draws the IconTiles in this view with `fill`. Catalog only.
    package func iconTileFill(_ fill: IconTileFill) -> some View {
        environment(\.iconTileFill, fill)
    }
}
