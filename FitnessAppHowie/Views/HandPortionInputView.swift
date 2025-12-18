//
//  HandPortionInputView.swift
//  FitHowie
//
//  手掌法則輸入組件
//

import SwiftUI

/// 手掌法則輸入視圖
struct HandPortionInputView: View {
    @Binding var proteinPortions: Double
    @Binding var carbPortions: Double
    @Binding var vegPortions: Double
    @Binding var fatPortions: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("份量估算")
                    .font(.headline)
                
                Spacer()
                
                // 總卡路里預覽
                let totalCals = calculateTotalCalories()
                Text("約 \(Int(totalCals)) kcal")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.blue)
            }
            
            Text("使用手掌法則快速估算")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // 蛋白質
            PortionSlider(
                macroType: .protein,
                value: $proteinPortions
            )
            
            // 碳水
            PortionSlider(
                macroType: .carbs,
                value: $carbPortions
            )
            
            // 蔬菜
            PortionSlider(
                macroType: .vegetables,
                value: $vegPortions
            )
            
            // 油脂
            PortionSlider(
                macroType: .fats,
                value: $fatPortions
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func calculateTotalCalories() -> Double {
        var total = 0.0
        total += MacroType.protein.estimatedCalories(portions: proteinPortions)
        total += MacroType.carbs.estimatedCalories(portions: carbPortions)
        total += MacroType.vegetables.estimatedCalories(portions: vegPortions)
        total += MacroType.fats.estimatedCalories(portions: fatPortions)
        return total
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

// MARK: - Preview

#Preview {
    ScrollView {
        HandPortionInputView(
            proteinPortions: .constant(1.5),
            carbPortions: .constant(2.0),
            vegPortions: .constant(1.0),
            fatPortions: .constant(0.5)
        )
        .padding()
    }
}
