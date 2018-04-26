
import Foundation
@testable import Corridor

struct MockCorridorType: CorridorTypeProtocol {
    let name: String
    func convert(from value: String) -> Any? {
        return nil
    }
}
