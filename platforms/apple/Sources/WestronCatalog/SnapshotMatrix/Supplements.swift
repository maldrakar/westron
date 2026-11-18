extension ComponentMatrix.Supplement {
    /// Every component's supplementary sheets (#72), hand-written: what no contract option sets but the owner reviews
    /// with the matrix. Each is defined with its component's catalog code; `ComponentMatrix.supplements` derives its
    /// sheets from the generated matrix, and `tools/apple/snapshot-matrix.sh` captures them in the same run and the same
    /// captures as the generated sheets. They are not catalog entries, so the accessibility audit does not walk them.
    static let all: [Self] = [
        .buttonLabelWithoutIcon, .textFieldCardNotes, .textFieldSecure, .textFieldOnSurface,
        .textFieldOnSunken,
    ]
}
