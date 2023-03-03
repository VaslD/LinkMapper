import ArgumentParser
import Foundation
import TabularData

@main
struct LinkMapper: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Link Map Analysis",
        version: "2.0.0"
    )

    @Option(name: .shortAndLong, help: "Max number of lines in summary table.")
    var lines: Int?

    @Argument(help: "Path to link map file.")
    var filePath: String

    func run() async throws {
        let stopwatch = ContinuousClock()

        print("Reading file into memory…", terminator: " ")
        var time = stopwatch.now
        let data = try Data(contentsOf: URL(fileURLWithPath: self.filePath))
        guard let string = String(data: data, encoding: .macOSRoman) else {
            throw ExitCode(EX_DATAERR)
        }
        let lines = string.components(separatedBy: "\n")
        print("[OK] (\((stopwatch.now - time).formatted()))")
        print(
            """
            Link Map File: \(Measurement(value: Double(data.count), unit: UnitInformationStorage.bytes)
                .formatted(.byteCount(style: .file))), \
            \(lines.count.formatted()) lines
            """,
            terminator: "\n\n"
        )

        print("Building state machine…  ", terminator: " ")
        time = stopwatch.now
        let states = State.buildStateMachine(lines)
        print("[OK] (\((stopwatch.now - time).formatted()))", terminator: "\n\n")

        print("Processing entries…      ", terminator: " ")
        time = stopwatch.now
        let graph = ObjectGraph()
        await withTaskGroup(of: Void.self) { tasks in
            for state in states {
                switch state {
                case let .path(path):
                    graph.path = path

                case let .architecture(arch):
                    graph.architecture = arch

                case let .objects(range):
                    for line in lines[range] {
                        tasks.addTask {
                            guard let object = ObjectFile(line) else {
                                return
                            }
                            graph.insert(object)
                        }
                    }

                case let .sections(range):
                    for line in lines[range] {
                        guard !line.isEmpty else {
                            continue
                        }
                        tasks.addTask {
                            _ = MachOSection(line)
                        }
                    }

                case let .symbols(range):
                    for line in lines[range] {
                        guard !line.isEmpty else {
                            continue
                        }
                        tasks.addTask {
                            let symbol = Symbol(line)
                            graph.insert(symbol)
                        }
                    }

                case .stripped:
                    break
                }
            }

            await tasks.waitForAll()
        }
        print("[OK] (\((stopwatch.now - time).formatted()))")
        print(graph, terminator: "\n\n")
        
        print("Generating summary…      ", terminator: " ")
        time = stopwatch.now
        let summary = graph.summarize()
        var table = DataFrame()
        table.append(column: Column<String>(name: "Object", capacity: summary.count))
        table.append(column: Column<Int>(name: "Size", capacity: summary.count))
        for (key, value) in summary {
            table.append(row: URL(filePath: key).lastPathComponent, value)
        }
        print("[OK] (\((stopwatch.now - time).formatted()))", terminator: "\n\n")
        
        var format = FormattingOptions()
        format.integerFormatStyle = IntegerFormatStyle().grouping(.automatic).notation(.compactName)
        format.includesColumnTypes = false
        if let lines = self.lines {
            format.maximumRowCount = lines
        } else {
            format.maximumRowCount = summary.count
        }
        print(table.sorted(on: "Size", order: .descending).description(options: format))
    }
}
