import Foundation

struct ObjectFile: Equatable, Hashable {
    let path: URL
    let name: String
    var size: Int

    init(_ path: String, _ name: String) {
        self.path = URL(fileURLWithPath: path)
        self.name = name
        self.size = 0
    }

    mutating func grow(_ size: Int) {
        self.size += size
    }
}
