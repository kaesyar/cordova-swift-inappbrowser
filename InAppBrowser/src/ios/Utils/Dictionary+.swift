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
