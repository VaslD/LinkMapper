enum State: Equatable, Hashable, Sendable {
    case path(String)
    case architecture(String)
    case objects(Range<Int>)
    case sections(Range<Int>)
    case symbols(Range<Int>)
    case stripped(Range<Int>)

    static func buildStateMachine(_ lines: [any StringProtocol]) -> [State] {
        var states = [State]()
        func transition(to state: Int, _ range: Range<Int>) {
            switch state {
            case 1:
                states.append(.objects(range))
            case 2:
                states.append(.sections(range))
            case 3:
                states.append(.symbols(range))
            case 4:
                states.append(.stripped(range))
            default:
                fatalError("Internal error: invalid state.")
            }
        }

        var state: Int?
        var startIndex: Int?
        for i in 0..<lines.count {
            let line = lines[i]
            guard line.hasPrefix("#") else {
                continue
            }

            let segments = line.components(separatedBy: ":")
            let next: Int
            switch String(segments[0].dropFirst(2)) {
            case "Path":
                states.append(.path(String(segments[1].dropFirst())))
                continue

            case "Arch":
                states.append(.architecture(String(segments[1].dropFirst())))
                continue

            case "Object files":
                next = 1
            case "Sections":
                next = 2
            case "Symbols":
                next = 3
            case "Dead Stripped Symbols":
                next = 4

            default:
                startIndex = i + 1
                continue
            }

            if let start = startIndex {
                transition(to: state!, start..<i)
            }
            state = next
            startIndex = i + 1
        }
        if let state, let start = startIndex {
            transition(to: state, start..<lines.count)
        }

        return states
    }
}
