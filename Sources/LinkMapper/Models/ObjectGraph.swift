import Foundation

class ObjectGraph: @unchecked Sendable, CustomStringConvertible {
    let lock = ReadWriteLock()
    
    var path: String!
    var architecture: String!

    var objects = [Int: ObjectFile]()
    var symbols = [Int: [Symbol]]()

    init() {}

    func insert(_ object: ObjectFile) {
        self.lock.write()
        self.objects[object.id] = object
        self.lock.unlock()
    }

    func insert(_ symbol: Symbol) {
        self.lock.read()
        var symbols = self.symbols[symbol.object] ?? []
        self.lock.unlock()
        symbols.append(symbol)

        self.lock.write()
        self.symbols[symbol.object] = symbols
        self.lock.unlock()
    }
    
    func summarize() -> [String: Int] {
        var dict = [String: Int]()
        self.lock.read()
        for object in self.objects.values {
            let key = object.name?.isEmpty != false ? "<Main Executable>" : object.path
            var subtotal = dict[key] ?? 0
            subtotal += self.symbols[object.id]?.reduce(into: 0) { $0 += $1.size } ?? 0
            dict[key] = subtotal
        }
        self.lock.unlock()
        return dict
    }

    var description: String {
        self.lock.read()
        let string =
            """
            Object Graph: \
            \(self.objects.count.formatted()) objects, \
            \(self.symbols.reduce(into: 0) { $0 += $1.value.count }.formatted()) symbols
            """
        self.lock.unlock()
        return string
    }
}
