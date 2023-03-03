import ArgumentParser
import Foundation
import TabularData

@main
struct Main: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Link Map 解析和数据统计工具",
        version: "1.1.0"
    )

    static let formatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 2
        formatter.unitOptions = .naturalScale
        return formatter
    }()

    @Option(name: .shortAndLong, help: "输出进度和调试信息。")
    var verbose = false

    @Option(name: .shortAndLong, help: "限制统计表格最大行数。")
    var linesInSummary: Int?

    @Option(name: .long, help: "读取指定条数符号后提前终止。仅供调试，最终统计数据无意义。")
    var earlyExitThreshold: Int?

    @Argument(help: "Link Map 文件路径。")
    var filePath: String

    func run() async throws {
        guard let reader = LineReader(URL(fileURLWithPath: filePath)) else {
            print("Unreadable file: \(self.filePath)")
            throw ExitCode(EX_DATAERR)
        }

        var groups = [URL: ObjectsGroup]()
        var objects = [Int: ObjectFile]()
        var sectionSize = 0

        var state: State?
        var records = 0
        fileParser: for var line in reader {
            if let header = line.firstMatch(of: #/^#\s+(.*):\s*(.*)$/#),
               let next = State(rawValue: String(header.1)) {
                state = next
                print()
                print("SM -> [\(next)]")
                line = String(header.2)
            }

            guard !line.isEmpty else {
                continue
            }
            guard !line.hasPrefix("#") else {
                continue
            }

            switch state {
            case .none:
                continue

            case .path:
                print("Path: \(line)")

            case .architecture:
                print("Arch: \(line)")

            case .objects:
                let match = line.wholeMatch(of: #/\[\s*(\d+)\]\s+([^\(]+)(?:\(([^\)]*)\))?/#)!
                let id = Int(match.1)!
                let path: String
                let name: String
                if let object = match.3 {
                    path = String(match.2)
                    name = String(object)
                } else {
                    let fileURL = URL(fileURLWithPath: String(match.2))
                    path = fileURL.deletingLastPathComponent().path
                    name = fileURL.lastPathComponent
                }
                guard !path.hasPrefix("/Applications/Xcode"), name != "linker synthesized" else {
                    continue
                }
                objects[id] = ObjectFile(path, name)

            case .sections:
                let section = MachOSection(line)
                sectionSize += section.size
                if self.verbose {
                    let size = Self.formatter.string(from: Measurement(value: Double(section.size),
                                                                       unit: UnitInformationStorage.bytes))
                    print("MACH-O += \(size)")
                }

            case .symbols:
                let symbol = Symbol(line)
                guard var object = objects[symbol.object] else {
                    continue
                }
                object.grow(symbol.size)
                objects[symbol.object] = object
                records += 1
                if self.verbose {
                    let size = Self.formatter.string(from: Measurement(value: Double(symbol.size),
                                                                       unit: UnitInformationStorage.bytes))
                    print("MACH-O += \(size)")
                }
                if let threshold = self.earlyExitThreshold, records > threshold {
                    print("=> EARLY EXIT!")
                    break fileParser
                }

            case .stripped:
                guard self.verbose else {
                    break fileParser
                }

                let symbol = DeadStrippedSymbol(line)
                let size = Self.formatter.string(from: Measurement(value: Double(symbol.size),
                                                                   unit: UnitInformationStorage.bytes))
                print("MACH-O -= \(size)")
            }
        }

        print()
        print("Generating summary...")

        for (_, object) in objects {
            var group: ObjectsGroup
            if let item = groups[object.path] {
                group = item
            } else {
                group = ObjectsGroup(object.path)
            }
            group.insert(object)
            groups[object.path] = group
        }

        var frame = DataFrame()
        frame.append(column: Column<String>(name: "Object File", capacity: groups.count))
        frame.append(column: Column<Int>(name: "Size", capacity: groups.count))

        for (path, objects) in groups {
            let size = objects.size
            guard size > 0 else {
                continue
            }
            frame.append(row: path.lastPathComponent, objects.size)
            sectionSize += size
        }

        var format = FormattingOptions()
        format.integerFormatStyle = IntegerFormatStyle().grouping(.automatic).notation(.compactName)
        format.includesColumnTypes = false
        if let lines = self.linesInSummary {
            format.maximumRowCount = lines
        } else {
            format.maximumRowCount = groups.count
        }
        print()
        print(frame.sorted(on: "Size", order: .descending).description(options: format))

        print()
        let size = Self.formatter.string(from: Measurement(value: Double(sectionSize),
                                                           unit: UnitInformationStorage.bytes))
        print("Mach-O：\(size) (from \(objects.count.formatted()) objects, \(records.formatted()) symbols)")

        if self.earlyExitThreshold != nil {
            print()
            print("\u{001B}[0;31m因为一个调试参数，Link Mapper 提前终止。")
        }
    }
}
