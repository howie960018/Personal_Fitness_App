import Foundation
import SwiftData

@Model
final class NutritionEntry {
    var timestamp: Date
    var mealType: String
    var entryDescription: String
    var photoFilename: String?
    
    // 基本記錄模式
    var amount: Double
    var unit: NutritionUnit
    
    // 手掌法則模式
    var proteinPortions: Double?
    var carbPortions: Double?
    var vegPortions: Double?
    var fatPortions: Double?
    
    var note: String?
    
    // 修正：將實際儲存的屬性改為可選型，以避免舊資料讀取時崩潰
    var primitiveStatus: EntryStatus?
    
    // 提供一個安全的存取介面，若為 nil 則回退至 .complete
    var status: EntryStatus {
        get { primitiveStatus ?? .complete }
        set { primitiveStatus = newValue }
    }
    
    var photoPath: String? {
        guard let filename = photoFilename else { return nil }
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent(filename).path
    }
    
    var estimatedCalories: Double {
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
        photoFilename: String? = nil,
        amount: Double = 0,
        unit: NutritionUnit = .handPortion,
        proteinPortions: Double? = nil,
        carbPortions: Double? = nil,
        vegPortions: Double? = nil,
        fatPortions: Double? = nil,
        note: String? = nil,
        status: EntryStatus = .complete
    ) {
        self.timestamp = timestamp
        self.mealType = mealType
        self.entryDescription = entryDescription
        self.photoFilename = photoFilename
        self.amount = amount
        self.unit = unit
        self.proteinPortions = proteinPortions
        self.carbPortions = carbPortions
        self.vegPortions = vegPortions
        self.fatPortions = fatPortions
        self.note = note
        self.primitiveStatus = status // 賦值給原始屬性
    }
}
