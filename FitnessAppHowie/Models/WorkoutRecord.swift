//
//  WorkoutRecord.swift
//  FitHowie
//
//  訓練紀錄模型
//

import Foundation
import SwiftData

@Model
final class WorkoutRecord {
    var timestamp: Date
    var trainingType: TrainingType
    @Relationship(deleteRule: .cascade) var exerciseDetails: [ExerciseSet]
    var durationMinutes: Int
    var note: String?
    
    var mediaFilename: String?
    var mediaType: String?
    
    var totalVolume: Double {
        exerciseDetails.reduce(0) { $0 + $1.totalVolume }
    }
    
    // MARK: - 新增：取得已排序的動作列表 (給 UI 用)
    var sortedExercises: [ExerciseSet] {
        exerciseDetails.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var mediaURL: URL? {
        guard let filename = mediaFilename else { return nil }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename)
    }
    
    init(
        timestamp: Date = Date(),
        trainingType: TrainingType,
        exerciseDetails: [ExerciseSet] = [],
        durationMinutes: Int = 0,
        note: String? = nil,
        mediaFilename: String? = nil,
        mediaType: String? = nil
    ) {
        self.timestamp = timestamp
        self.trainingType = trainingType
        self.exerciseDetails = exerciseDetails
        self.durationMinutes = durationMinutes
        self.note = note
        self.mediaFilename = mediaFilename
        self.mediaType = mediaType
    }
}
