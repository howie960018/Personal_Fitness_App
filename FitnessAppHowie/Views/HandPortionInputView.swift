//
//  HandPortionInputView.swift
//  FitHowie
//
//  手掌法則輸入組件 - 支援手動修改熱量
//

import SwiftUI

/// 手掌法則輸入視圖
struct HandPortionInputView: View {
    @Binding var proteinPortions: Double
    @Binding var carbPortions: Double
    @Binding var vegPortions: Double
    @Binding var fatPortions: Double
    
    // MARK: - 新增：綁定外部的熱量變數
    @Binding var calories: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("份量估算")
                    .font(.headline)
                
                Spacer()
                
                // MARK: - 修改：改為可輸入的 TextField
                HStack(spacing: 4) {
                    Text("約")
                        .foregroundStyle(.secondary)
                    
                    TextField("熱量", value: $calories, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text("kcal")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.blue)
                }
            }
            
            Text("滑動調整份數，或直接點擊上方數字修改熱量")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // 各個滑桿 (加入 onChange 來自動更新熱量)
            PortionSlider(
                macroType: .protein,
                value: $proteinPortions
            )
            .onChange(of: proteinPortions) { updateCalories() }
            
            PortionSlider(
                macroType: .carbs,
                value: $carbPortions
            )
            .onChange(of: carbPortions) { updateCalories() }
            
            PortionSlider(
                macroType: .vegetables,
                value: $vegPortions
            )
            .onChange(of: vegPortions) { updateCalories() }
            
            PortionSlider(
                macroType: .fats,
                value: $fatPortions
            )
            .onChange(of: fatPortions) { updateCalories() }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        // 畫面載入時若為0則先算一次初始值
        .onAppear {
            if calories == 0 { updateCalories() }
        }
    }
    
    private func updateCalories() {
        var total = 0.0
        total += MacroType.protein.estimatedCalories(portions: proteinPortions)
        total += MacroType.carbs.estimatedCalories(portions: carbPortions)
        total += MacroType.vegetables.estimatedCalories(portions: vegPortions)
        total += MacroType.fats.estimatedCalories(portions: fatPortions)
        
        // 當使用者移動滑桿時，重新計算並覆蓋手動輸入值
        // 這是為了讓滑桿與數字保持連動
        withAnimation {
            calories = total
        }
    }
}

/// 單一營養素滑桿組件
struct PortionSlider: View {
    let macroType: MacroType
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(macroType.emoji)
                    .font(.title3)
                
                Text(macroType.rawValue)
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                // 顯示份量
                Text("\(value, specifier: "%.1f") \(macroType.unitName)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(colorForMacro(macroType))
                    .bold()
            }
            
            HStack(spacing: 12) {
                // 滑桿
                Slider(value: $value, in: 0...5, step: 0.5)
                    .tint(colorForMacro(macroType))
                
                // 快速調整按鈕
                HStack(spacing: 4) {
                    Button {
                        if value > 0 {
                            value -= 0.5
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(colorForMacro(macroType))
                    }
                    
                    Button {
                        if value < 5 {
                            value += 0.5
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(colorForMacro(macroType))
                    }
                }
            }
            
            // 估算資訊
            HStack {
                Text("約 \(Int(macroType.estimatedWeight(portions: value)))g")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(macroType.estimatedCalories(portions: value))) kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private func colorForMacro(_ macro: MacroType) -> Color {
        switch macro {
        case .protein: return .red
        case .carbs: return .orange
        case .vegetables: return .green
        case .fats: return .yellow
        }
    }
}
