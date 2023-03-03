import Foundation

struct ObjectFile: Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let path: String
    let name: String?
    
    init?(_ line: String) {
        let match = line.wholeMatch(of: #/\[\s*(\d+)\]\s+([^\(]+)(?:\(([^\)]*)\))?/#)!
        self.id = Int(match.1)!
        self.path = String(match.2)
        if let object = match.3 {
            self.name = String(object)
        } else {
            self.name = nil
        }
        
        if path.hasPrefix("/Applications/Xcode") || name == "linker synthesized" {
            return nil
        }
    }
}
