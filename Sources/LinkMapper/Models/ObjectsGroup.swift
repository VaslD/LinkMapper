import Foundation

struct ObjectsGroup {
    let path: URL
    var objects: Set<ObjectFile>

    init(_ path: URL) {
        self.path = path
        self.objects = []
    }

    mutating func insert(_ object: ObjectFile) {
        self.objects.insert(object)
    }

    var size: Int {
        self.objects.reduce(into: 0) {
            $0 += $1.size
        }
    }
}
