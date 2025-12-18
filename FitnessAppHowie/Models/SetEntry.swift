//
//  SetEntry.swift
//  FitHowie
//
//  單組數據模型
//

import Foundation
import SwiftData

@Model
final class SetEntry {
    @Attribute(.unique) var id: UUID
    var weight: Double
    var reps: Int
    
    init(weight: Double, reps: Int) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
    }
}
