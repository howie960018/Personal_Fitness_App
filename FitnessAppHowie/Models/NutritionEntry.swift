import Foundation
import SwiftData

@Model
final class NutritionEntry {
    var timestamp: Date
    var mealType: String
    var entryDescription: String
    
    // MARK: - 修改：支援多張照片
    var photoFilenames: [String] = [] // 改用陣列儲存多個檔名
    
    // 為了向下相容,保留舊欄位但標記為 deprecated
    @available(*, deprecated, message: "請使用 photoFilenames")
    var photoFilename: String?
    
    // 基本記錄模式
    var amount: Double
    var unit: NutritionUnit
    
    // 手掌法則模式
    var proteinPortions: Double?
    var carbPortions: Double?
    var vegPortions: Double?
    var fatPortions: Double?
    
    // 手動設定的熱量 (總熱量)
    var manualCalories: Double?
    
    var note: String?
    var primitiveStatus: EntryStatus?
    
    var status: EntryStatus {
        get { primitiveStatus ?? .complete }
        set { primitiveStatus = newValue }
    }
    
    // MARK: - 向下相容：取得第一張照片路徑
    var photoPath: String? {
        // 優先使用新的多張照片陣列
        if let firstFilename = photoFilenames.first {
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            return documentsPath.appendingPathComponent(firstFilename).path
        }
        // 如果新陣列是空的,回退到舊欄位
        guard let filename = photoFilename else { return nil }
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent(filename).path
    }
    
    // MARK: - 新增：取得所有照片的 URL
    var photoURLs: [URL] {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        var urls: [URL] = []
        
        // 先加入新格式的照片
        for filename in photoFilenames {
            urls.append(documentsPath.appendingPathComponent(filename))
        }
        
        // 如果有舊格式的照片且不在新陣列中,也加入
        if let oldFilename = photoFilename, !photoFilenames.contains(oldFilename) {
            urls.append(documentsPath.appendingPathComponent(oldFilename))
        }
        
        return urls
    }
    
    var estimatedCalories: Double {
        // 1. 如果有手動存入的總熱量，最優先使用
        if let manual = manualCalories {
            return manual
        }
        
        // 2. 如果單位本身就是「卡路里」，那 amount 就是熱量
        if unit == .calorie {
            return amount
        }
        
        // 3. 手掌法則計算
        var total = 0.0
        if let protein = proteinPortions {
            total += MacroType.protein.estimatedCalories(portions: protein)
        }
        if let carbs = carbPortions {
            total += MacroType.carbs.estimatedCalories(portions: carbs)
        }
        if let veg = vegPortions {
            total += MacroType.vegetables.estimatedCalories(portions: veg)
        }
        if let fat = fatPortions {
            total += MacroType.fats.estimatedCalories(portions: fat)
        }
        return total
    }
    
    var isHandPortionMode: Bool {
        proteinPortions != nil || carbPortions != nil || vegPortions != nil || fatPortions != nil
    }
    
    init(
        timestamp: Date = Date(),
        mealType: String,
        entryDescription: String,
        photoFilenames: [String] = [], // 新增：照片陣列
        photoFilename: String? = nil,   // 保留舊參數以相容
        amount: Double = 0,
        unit: NutritionUnit = .handPortion,
        proteinPortions: Double? = nil,
        carbPortions: Double? = nil,
        vegPortions: Double? = nil,
        fatPortions: Double? = nil,
        manualCalories: Double? = nil,
        note: String? = nil,
        status: EntryStatus = .complete
    ) {
        self.timestamp = timestamp
        self.mealType = mealType
        self.entryDescription = entryDescription
        
        // 處理照片相容性
        if !photoFilenames.isEmpty {
            self.photoFilenames = photoFilenames
        } else if let filename = photoFilename {
            self.photoFilenames = [filename] // 轉換舊格式為新格式
        } else {
            self.photoFilenames = []
        }
        
        self.photoFilename = photoFilename
        self.amount = amount
        self.unit = unit
        self.proteinPortions = proteinPortions
        self.carbPortions = carbPortions
        self.vegPortions = vegPortions
        self.fatPortions = fatPortions
        self.manualCalories = manualCalories
        self.note = note
        self.primitiveStatus = status
    }
}
