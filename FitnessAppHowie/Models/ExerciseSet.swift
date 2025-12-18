//
//  ExerciseSet.swift
//  FitHowie
//
//  單一動作與組數模型 - 修正資料庫遷移問題
//

import Foundation
import SwiftData

@Model
final class ExerciseSet {
    @Attribute(.unique) var id: UUID
    var exerciseName: String
    var exerciseType: ExerciseType
    var muscleGroup: MuscleGroup
    @Relationship(deleteRule: .cascade) var sets: [SetEntry]
    var note: String?
    
    var mediaFilename: String?
    var mediaType: String?
    
    // MARK: - 修正：給予預設值，讓 SwiftData 知道舊資料該填什麼
    var orderIndex: Int = 0
    
    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    var maxWeight: Double {
        sets.map { $0.weight }.max() ?? 0
    }
    
    var mediaURL: URL? {
        guard let filename = mediaFilename else { return nil }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename)
    }
    
    init(
        exerciseName: String,
        exerciseType: ExerciseType,
        muscleGroup: MuscleGroup,
        sets: [SetEntry] = [],
        note: String? = nil,
        mediaFilename: String? = nil,
        mediaType: String? = nil,
        orderIndex: Int = 0
    ) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.exerciseType = exerciseType
        self.muscleGroup = muscleGroup
        self.sets = sets
        self.note = note
        self.mediaFilename = mediaFilename
        self.mediaType = mediaType
        self.orderIndex = orderIndex
    }
}
