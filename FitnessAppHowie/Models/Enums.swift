//
//  Enums.swift
//  FitHowie
//
//  定義所有需要的列舉類型
//

import Foundation

/// 訓練類型:有氧或無氧
enum TrainingType: String, Codable, CaseIterable {
    case aerobic = "有氧"
    case anaerobic = "無氧"
}

/// 重訓類型:器械或自由重量
enum ExerciseType: String, Codable, CaseIterable {
    case machine = "器械"
    case freeWeight = "自由重量"
}

/// 目標肌肉群
enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "胸"
    case back = "背"
    case legs = "腿"
    case shoulders = "肩"
    case arms = "手臂"
    case core = "核心"
    case other = "其他"
}

/// 飲食單位
enum NutritionUnit: String, Codable, CaseIterable {
    case serving = "份數"
    case weight = "重量(克)"
    case calorie = "卡路里"
    case handPortion = "手掌份量"
}

/// 重量單位
enum WeightUnit: String, Codable, CaseIterable {
    case kg = "公斤 (kg)"
    case lb = "磅 (lb)"
    
    /// 將當前單位轉換為公斤
    func toKg(_ value: Double) -> Double {
        switch self {
        case .kg:
            return value
        case .lb:
            return value * 0.453592 // 1 磅 = 0.453592 公斤
        }
    }
    
    /// 從公斤轉換為當前單位
    func fromKg(_ kg: Double) -> Double {
        switch self {
        case .kg:
            return kg
        case .lb:
            return kg * 2.20462 // 1 公斤 = 2.20462 磅
        }
    }
    
    /// 顯示用的簡短單位
    var shortName: String {
        switch self {
        case .kg: return "kg"
        case .lb: return "lb"
        }
    }
}

/// 預設運動項目
struct ExerciseLibrary {
    
    /// 根據肌肉群和訓練類型取得推薦的運動項目
    static func exercises(for muscleGroup: MuscleGroup, exerciseType: ExerciseType) -> [String] {
        switch (muscleGroup, exerciseType) {
        // MARK: - 自由重量
        case (.chest, .freeWeight):
            return [
                "槓鈴臥推 - 平板",
                "槓鈴臥推 - 上斜",
                "槓鈴臥推 - 下斜",
                "啞鈴臥推 - 平板",
                "啞鈴臥推 - 上斜",
                "啞鈴臥推 - 下斜",
                "啞鈴飛鳥",
                "雙槓撐體",
                "其他"
            ]
            
        case (.back, .freeWeight):
            return [
                "硬舉 - 傳統",
                "硬舉 - 相撲",
                "引體向上",
                "反手引體向上",
                "槓鈴划船",
                "單臂啞鈴划船",
                "啞鈴直臂下壓",
                "其他"
            ]
            
        case (.legs, .freeWeight):
            return [
                "槓鈴深蹲 - 背槓",
                "槓鈴深蹲 - 前槓",
                "高腳杯深蹲",
                "羅馬尼亞硬舉 (RDL)",
                "弓箭步 - 行走",
                "弓箭步 - 後撤",
                "保加利亞分腿蹲",
                "站姿提踵",
                "其他"
            ]
            
        case (.shoulders, .freeWeight):
            return [
                "槓鈴肩推",
                "軍事推舉",
                "啞鈴肩推",
                "啞鈴側平舉",
                "啞鈴前平舉",
                "俯身飛鳥",
                "其他"
            ]
            
        case (.arms, .freeWeight):
            return [
                "槓鈴彎舉",
                "啞鈴彎舉",
                "錘式彎舉",
                "窄握臥推",
                "法式推舉",
                "顱骨粉碎者",
                "過頂臂屈伸",
                "其他"
            ]
            
        case (.core, .freeWeight):
            return [
                "負重棒式",
                "俄羅斯轉體",
                "懸垂舉腿",
                "負重捲腹",
                "其他"
            ]
            
        // MARK: - 器械
        case (.chest, .machine):
            return [
                "機械坐姿推胸",
                "蝴蝶機夾胸",
                "纜繩夾胸",
                "史密斯臥推",
                "其他"
            ]
            
        case (.back, .machine):
            return [
                "滑輪下拉",
                "機械坐姿划船",
                "輔助引體向上機",
                "直臂下壓 - 纜繩",
                "T槓划船",
                "其他"
            ]
            
        case (.legs, .machine):
            return [
                "腿推機",
                "坐姿腿屈伸",
                "俯臥腿後勾",
                "坐姿腿後勾",
                "髖外展機",
                "髖內收機",
                "史密斯深蹲",
                "腿推小腿",
                "其他"
            ]
            
        case (.shoulders, .machine):
            return [
                "機械肩推",
                "蝴蝶機反向飛鳥",
                "纜繩側平舉",
                "臉拉 - 纜繩",
                "史密斯肩推",
                "其他"
            ]
            
        case (.arms, .machine):
            return [
                "牧師椅彎舉機",
                "纜繩彎舉",
                "纜繩下壓",
                "機械臂屈伸",
                "其他"
            ]
            
        case (.core, .machine):
            return [
                "捲腹機",
                "旋轉核心機",
                "纜繩捲腹",
                "其他"
            ]
            
        case (.other, _):
            return ["其他"]
        }
    }
}


/// 營養素類型（手掌法則使用）
enum MacroType: String, Codable, CaseIterable {
    case protein = "蛋白質"
    case carbs = "碳水化合物"
    case vegetables = "蔬菜"
    case fats = "油脂"
    
    var emoji: String {
        switch self {
        case .protein: return "🥩"
        case .carbs: return "🍚"
        case .vegetables: return "🥦"
        case .fats: return "🥜"
        }
    }
    
    var unitName: String {
        switch self {
        case .protein: return "手掌"
        case .carbs: return "捧"
        case .vegetables: return "拳頭"
        case .fats: return "拇指"
        }
    }
    
    /// 估算每單位的卡路里（可根據個人調整）
    func estimatedCalories(portions: Double) -> Double {
        switch self {
        case .protein:
            return portions * 25 * 4  // 1手掌約25g蛋白質 × 4 kcal/g
        case .carbs:
            return portions * 30 * 4  // 1捧約30g碳水 × 4 kcal/g
        case .vegetables:
            return portions * 50 * 1  // 1拳頭約50g蔬菜 × 1 kcal/g (粗估)
        case .fats:
            return portions * 10 * 9  // 1拇指約10g油脂 × 9 kcal/g
        }
    }
    
    /// 估算重量（克）
    func estimatedWeight(portions: Double) -> Double {
        switch self {
        case .protein: return portions * 100  // 1手掌約100g肉
        case .carbs: return portions * 80     // 1捧約80g飯
        case .vegetables: return portions * 100  // 1拳頭約100g菜
        case .fats: return portions * 10      // 1拇指約10g油
        }
    }
}

/// 記錄狀態
enum EntryStatus: String, Codable {
    case complete = "已完成"
    case pending = "待補完"  // 只拍了照片，還沒填寫份量
}

