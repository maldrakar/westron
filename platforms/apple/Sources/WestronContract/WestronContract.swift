// The contracts' vocabulary: the option enums westron's component contracts give, such as `ButtonVariant`,
// `ButtonSize` and `RuleAxis`, generated into Generated/ by `tools/westron generate` from spec/components/.
//
// It imports nothing, not even Foundation, as WestronTokens does: a product's shared code, which cannot import SwiftUI
// and may build for WebAssembly and Linux, imports it so that its models name westron's options instead of sizes,
// colors and fonts (decisions/0017). WestronUI re-exports it, so a view that imports WestronUI sees the same types.
// Nothing is declared here by hand: `tools/westron lint api-parity` reports anything the contracts do not give.
