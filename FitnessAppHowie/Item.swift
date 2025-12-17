//
//  Item.swift
//  FitnessAppHowie
//
//  Created by 曾浩儀 on 2025/12/17.
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
