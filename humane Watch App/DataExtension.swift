//
//  DataExtension.swift
//  humane Watch App
//
//  Created by Olivia Li on 11/15/23.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
