//
//  Item.swift
//  aiki-exam
//
//  Created by Slava Davydov on 01.03.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
