//
//  ExerciseSet.swift
//  FitHowie
//
//  單一動作與組數模型 - 支援多個媒體檔案
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
    
    // MARK: - 修改：支援多個媒體檔案
    var mediaFilenames: [String] = []  // 新增：媒體檔案陣列
    var mediaTypes: [String] = []      // 新增：對應的媒體類型陣列 (photo/video)
    
    // 向下相容：保留舊欄位
    @available(*, deprecated, message: "請使用 mediaFilenames")
    var mediaFilename: String?
    @available(*, deprecated, message: "請使用 mediaTypes")
    var mediaType: String?
    
    var orderIndex: Int = 0
    
    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    var maxWeight: Double {
        sets.map { $0.weight }.max() ?? 0
    }
    
    // MARK: - 向下相容：取得第一個媒體 URL
    var mediaURL: URL? {
        guard let filename = mediaFilenames.first ?? mediaFilename else { return nil }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent(filename)
    }
    
    // MARK: - 新增：取得所有媒體 URL
    var mediaURLs: [URL] {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        var urls: [URL] = []
        
        // 先加入新格式的媒體
        for filename in mediaFilenames {
            urls.append(documentsPath.appendingPathComponent(filename))
        }
        
        // 向下相容：如果有舊格式的媒體且不在新陣列中，也加入
        if let oldFilename = mediaFilename, !mediaFilenames.contains(oldFilename) {
            urls.append(documentsPath.appendingPathComponent(oldFilename))
        }
        
        return urls
    }
    
    // MARK: - 新增：取得媒體項目（檔名+類型）
    struct MediaItem: Identifiable {
        let id = UUID()
        let filename: String
        let type: String  // "photo" or "video"
        
        var url: URL? {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first?.appendingPathComponent(filename)
        }
    }
    
    var mediaItems: [MediaItem] {
        var items: [MediaItem] = []
        
        // 從新格式建立
        for (index, filename) in mediaFilenames.enumerated() {
            let type = index < mediaTypes.count ? mediaTypes[index] : "photo"
            items.append(MediaItem(filename: filename, type: type))
        }
        
        // 向下相容：加入舊格式
        if let oldFilename = mediaFilename, !mediaFilenames.contains(oldFilename) {
            let oldType = mediaType ?? "photo"
            items.append(MediaItem(filename: oldFilename, type: oldType))
        }
        
        return items
    }
    
    init(
        exerciseName: String,
        exerciseType: ExerciseType,
        muscleGroup: MuscleGroup,
        sets: [SetEntry] = [],
        note: String? = nil,
        mediaFilenames: [String] = [],      // 新增參數
        mediaTypes: [String] = [],          // 新增參數
        mediaFilename: String? = nil,       // 保留舊參數以相容
        mediaType: String? = nil,           // 保留舊參數以相容
        orderIndex: Int = 0
    ) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.exerciseType = exerciseType
        self.muscleGroup = muscleGroup
        self.sets = sets
        self.note = note
        
        // 處理媒體相容性
        if !mediaFilenames.isEmpty {
            self.mediaFilenames = mediaFilenames
            self.mediaTypes = mediaTypes
        } else if let filename = mediaFilename {
            self.mediaFilenames = [filename]
            self.mediaTypes = [mediaType ?? "photo"]
        } else {
            self.mediaFilenames = []
            self.mediaTypes = []
        }
        
        self.mediaFilename = mediaFilename
        self.mediaType = mediaType
        self.orderIndex = orderIndex
    }
}
