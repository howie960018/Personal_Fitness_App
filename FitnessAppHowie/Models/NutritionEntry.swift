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
    
    // 手動設定的熱量 (總熱量)
    var manualCalories: Double?
    
    var note: String?
    var primitiveStatus: EntryStatus?
    
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
        photoFilename: String? = nil,
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
