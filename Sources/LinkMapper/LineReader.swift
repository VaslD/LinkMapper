import Foundation

public final class LineReader: Sequence {
    let file: UnsafeMutablePointer<FILE>

    public init?(_ fileURL: URL) {
        guard let file = fopen(fileURL.path, "r") else {
            return nil
        }
        self.file = file
    }

    deinit {
        fclose(self.file)
    }

    public func readLine() -> String? {
        var string: UnsafeMutablePointer<CChar>?
        defer { free(string) }
        var capacity = 0
        let length = getline(&string, &capacity, self.file)
        guard length != -1 else {
            return nil
        }
        guard length > 0 else {
            return String()
        }

        let endOfLine = string!.advanced(by: length - 1)
        if endOfLine.pointee == 0x0A /* LF */ {
            endOfLine.pointee = 0x00
        }

        return String(cString: string!)
    }

    // MARK: Sequence

    public func makeIterator() -> Iterator {
        fseek(self.file, 0, SEEK_SET)
        return Iterator(self)
    }

    public struct Iterator: IteratorProtocol {
        let reader: LineReader

        init(_ reader: LineReader) {
            self.reader = reader
        }

        public func next() -> String? {
            self.reader.readLine()
        }
    }
}
