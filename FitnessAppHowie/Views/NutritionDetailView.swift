//
//  NutritionDetailView.swift
//  FitHowie
//
//  飲食詳情視圖 - 支援多張照片輪播
//

import SwiftUI
import SwiftData

struct NutritionDetailView: View {
    let entry: NutritionEntry
    @State private var showingEditSheet = false
    @State private var currentPhotoIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - 修改：多張照片輪播
                if !entry.photoURLs.isEmpty {
                    TabView(selection: $currentPhotoIndex) {
                        ForEach(Array(entry.photoURLs.enumerated()), id: \.offset) { index, url in
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .tag(index)
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
                    
                    // 照片計數器
                    if entry.photoURLs.count > 1 {
                        HStack {
                            Spacer()
                            Text("\(currentPhotoIndex + 1) / \(entry.photoURLs.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemBackground).opacity(0.8))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .offset(y: -20)
                    }
                }
                
                // 2. 核心資訊卡片
                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(label: "餐別", value: entry.mealType)
                    DetailRow(label: "記錄時間", value: entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    DetailRow(label: "描述", value: entry.entryDescription)
                    
                    Divider()
                    
                    // 3. 份量與熱量顯示邏輯
                    if entry.isHandPortionMode {
                        // A. 手掌法則模式
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
                        // B. 精確計算模式
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(label: "份量", value: String(format: "%.1f %@", entry.amount, entry.unit.rawValue))
                            
                            if let totalCals = entry.manualCalories, entry.amount > 0 {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("熱量明細")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    let unitCals = totalCals / entry.amount
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(String(format: "%.0f", unitCals))
                                            .font(.body)
                                            .monospacedDigit()
                                        
                                        Text("kcal/\(entry.unit == .serving ? "份" : "單位")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("×")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 2)
                                        
                                        Text(String(format: "%g", entry.amount))
                                            .font(.body)
                                            .monospacedDigit()
                                        
                                        Text("=")
                                            .font(.body)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 2)
                                        
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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("編輯")
                }
            }
        }
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
