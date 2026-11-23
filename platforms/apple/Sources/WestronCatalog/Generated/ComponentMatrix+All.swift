// Generated from the contracts in spec/components by `tools/westron generate`. Do not edit: change the contracts and
// generate again (spec/conventions.md).
//
// Every component's snapshot matrix (#24), which `tools/apple/snapshot-matrix.sh` captures.

extension ComponentMatrix {
    /// Every component's snapshot matrix on the current OS, in the order of the contracts' ids: a component an OS lacks
    /// has no matrix there.
    public static let all: [ComponentMatrix] = {
        var all: [ComponentMatrix] = []
        all.append(contentsOf: [.button, .checkbox, .chip])
        #if !os(watchOS)
            all.append(.disclosure)
        #endif
        all.append(contentsOf: [.icon, .iconTile, .listRow, .rule, .surface, .text, .textField])
        return all
    }()
}
