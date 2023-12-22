import Foundation

struct CDVInAppBrowserOptions: Decodable {
    var beforeLoad: BeforeLoadOption? = .empty
    var beforeBlank: BeforeBlankOption? = .empty
    var hidden: HiddenOption? = .no
    var bottomOffset: NumericString? = .wrappedValue(0)
    
    enum CodingKeys: String, CodingKey {
        case beforeLoad = "beforeload"
        case beforeBlank = "beforeblank"
        case hidden = "hidden"
        case bottomOffset = "bottomoffset"
    }
}

extension CDVInAppBrowserOptions {
    init?(from string: String) {
        guard !string.isEmpty else {
            // initialize with default values
            self = CDVInAppBrowserOptions()
            return
        }
        
        guard let optionsDictionary = string.optionsDictionary else {
            return nil
        }
        guard let json = optionsDictionary.json else {
            return nil
        }
        guard let data = json.data(using: .utf8) else {
            return nil
        }
        guard let options = try? JSONDecoder().decode(Self.self, from: data) else {
            return nil
        }
        
        self = options
    }
}


enum BeforeLoadOption: String, Decodable {
    case yes, no, `get`, post
    case empty = ""
}

enum BeforeBlankOption: String, Decodable {
    case yes, no
    case empty = ""
}

enum HiddenOption: String, Decodable {
    case yes, no
    case empty = ""
}

enum NumericString: Decodable {
    case wrappedValue(Int)
    
    init(from decoder: Decoder) throws {
        guard   let stringValue = try? decoder.singleValueContainer().decode(String.self),
                let wrappedInteger = Int(stringValue) else {
            throw Error.wrongFormat
        }
        self = .wrappedValue(wrappedInteger)
    }
    
    enum Error: Swift.Error {
        case wrongFormat
    }
}

