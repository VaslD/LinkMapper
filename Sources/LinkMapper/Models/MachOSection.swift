struct MachOSection: Equatable, Hashable, Sendable {
    let address: UInt
    let size: Int
    let segment: String
    let section: String

    init(_ line: String) {
        let segments = line.components(separatedBy: "\t")
        self.address = UInt(segments[0].dropFirst(2), radix: 16)!
        self.size = Int(segments[1].dropFirst(2), radix: 16)!
        self.segment = String(segments[2])
        self.section = String(segments[3])
    }
}
