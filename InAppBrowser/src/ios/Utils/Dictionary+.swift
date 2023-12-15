//
//  Dictionary+.swift
//  NostrSecond
//
//  Created by Shakhzod Omonbayev on 26/10/23.
//

import Foundation

extension Dictionary {
    var json: String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8)
        } catch {
            return nil
        }
    }
}

extension String {
    var optionsDictionary: [String: String]? {
        let dict = self
            .components(separatedBy: ",")
            .compactMap { option -> (key: String, value: String)? in
                let keyValue = option.components(separatedBy: "=")
                if keyValue.count != 2 { return nil }
                return (key: keyValue[0], value: keyValue[1])
            }
            .reduce(into: [String:String]()) { dictionary, option in
                dictionary[option.key] = option.value
            }
        
        return dict.isEmpty ? nil : dict
    }
}
