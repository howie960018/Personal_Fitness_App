//
//  NutritionDetailView.swift
//  FitHowie
//
//  飲食詳情視圖 - 支援手掌法則與精確熱量計算顯示
//

import SwiftUI
import SwiftData

struct NutritionDetailView: View {
    let entry: NutritionEntry
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. 食物照片
                if let photoPath = entry.photoPath {
                    AsyncImage(url: URL(fileURLWithPath: photoPath)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
                }
                
                // 2. 核心資訊卡片
                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(label: "餐別", value: entry.mealType)
                    DetailRow(label: "記錄時間", value: entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    DetailRow(label: "描述", value: entry.entryDescription)
                    
                    Divider()
                    
                    // 3. 份量與熱量顯示邏輯
                    if entry.isHandPortionMode {
                        // MARK: - A. 手掌法則模式
                        VStack(alignment: .leading, spacing: 12) {
                            Text("份量估算 (手掌法則)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 15) {
                                if let protein = entry.proteinPortions, protein > 0 {
                                    MacroDetailIcon(emoji: "🥩", label: "蛋白質", value: protein, unit: "手掌")
                                }
                                if let carbs = entry.carbPortions, carbs > 0 {
                                    MacroDetailIcon(emoji: "🍚", label: "碳水", value: carbs, unit: "捧")
                                }
                                if let veg = entry.vegPortions, veg > 0 {
                                    MacroDetailIcon(emoji: "🥦", label: "蔬菜", value: veg, unit: "拳頭")
                                }
                                if let fat = entry.fatPortions, fat > 0 {
                                    MacroDetailIcon(emoji: "🥜", label: "油脂", value: fat, unit: "拇指")
                                }
                            }
                            
                            HStack {
                                Text("估算熱量")
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                                Text("\(Int(entry.estimatedCalories)) kcal")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.blue)
                            }
                            .padding(.top, 5)
                        }
                    } else {
                        // MARK: - B. 精確計算模式 (單位熱量 x 份數)
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(label: "份量", value: String(format: "%.1f %@", entry.amount, entry.unit.rawValue))
                            
                            // 顯示熱量計算公式
                            if let totalCals = entry.manualCalories, entry.amount > 0 {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("熱量明細")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    // 反推單位熱量
                                    let unitCals = totalCals / entry.amount
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        // 單位熱量
                                        Text(String(format: "%.0f", unitCals))
                                            .font(.body)
                                            .monospacedDigit()
                                        
                                        Text("kcal/\(entry.unit == .serving ? "份" : "單位")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        // 乘號
                                        Text("×")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 2)
                                        
                                        // 份數
                                        Text(String(format: "%g", entry.amount)) // %g 自動去除多餘的0
                                            .font(.body)
                                            .monospacedDigit()
                                        
                                        // 等號
                                        Text("=")
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 2)
                                        
                                        // 總熱量
                                        Text("\(Int(totalCals))")
                                            .font(.title3)
                                            .bold()
                                            .foregroundStyle(.blue)
                                        
                                        Text("kcal")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                            .bold()
                                    }
                                }
                            } else {
                                // 舊資料或無熱量時的 fallback
                                DetailRow(label: "估算熱量", value: "\(Int(entry.estimatedCalories)) kcal")
                            }
                        }
                    }
                    
                    // 4. 備註
                    if let note = entry.note, !note.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 5) {
                            Text("備註")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(note)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("飲食詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 右上角編輯按鈕
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("編輯")
                }
            }
        }
        // 彈出編輯頁面
        .sheet(isPresented: $showingEditSheet) {
            EditNutritionEntryView(entry: entry)
        }
    }
}

// MARK: - 輔助組件

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

/// 營養素小方塊 (用於詳情頁)
struct MacroDetailIcon: View {
    let emoji: String
    let label: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title2)
            Text(String(format: "%.1f", value))
                .font(.subheadline)
                .bold()
            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    let entry = NutritionEntry(
        mealType: "午餐",
        entryDescription: "茶葉蛋",
        amount: 2,
        unit: .serving,
        manualCalories: 140, // 模擬：70kcal * 2 = 140kcal
        note: "補充蛋白質"
    )
    
    return NavigationStack {
        NutritionDetailView(entry: entry)
    }
    .modelContainer(for: NutritionEntry.self, inMemory: true)
}
