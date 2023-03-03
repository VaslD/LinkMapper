struct Symbol {
    let address: UInt
    let size: Int
    let object: Int
    let name: String

    init(_ line: String) {
        let segments = line.components(separatedBy: "\t")
        self.address = UInt(segments[0].dropFirst(2), radix: 16)!
        self.size = Int(segments[1].dropFirst(2), radix: 16)!
        let match = segments[2].firstMatch(of: #/^\[\s*(\d+)\]\s+(.+)/#)!
        self.object = Int(match.1)!
        self.name = String(match.2)
    }
}
