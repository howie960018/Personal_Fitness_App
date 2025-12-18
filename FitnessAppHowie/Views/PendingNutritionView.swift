//
//  PendingNutritionView.swift
//  FitHowie
//
//  待補完飲食記錄視圖 - 修正舊資料相容性與手動熱量支援
//

import SwiftUI
import SwiftData

struct PendingNutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NutritionEntry.timestamp, order: .reverse) private var allEntries: [NutritionEntry]
    
    // 修正：手動過濾待補完的記錄，並處理舊資料 primitiveStatus 可能為 nil 的情況
    private var pendingEntries: [NutritionEntry] {
        allEntries.filter { ($0.primitiveStatus ?? .complete) == .pending }
    }
    
    @State private var selectedEntry: NutritionEntry?
    
    var body: some View {
        NavigationStack {
            Group {
                if pendingEntries.isEmpty {
                    emptyStateView
                } else {
                    pendingListView
                }
            }
            .navigationTitle("待補完記錄")
            // 使用 item 綁定彈出補完介面
            .sheet(item: $selectedEntry) { entry in
                CompletePendingEntryView(entry: entry)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("太棒了！")
                .font(.title2)
                .bold()
            Text("所有記錄都已補完")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var pendingListView: some View {
        List {
            Section {
                Text("點擊照片補完份量資訊")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(pendingEntries) { entry in
                Button {
                    selectedEntry = entry
                } label: {
                    PendingEntryRow(entry: entry)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteEntry(entry)
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    private func deleteEntry(_ entry: NutritionEntry) {
        if let filename = entry.photoFilename,
           let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath = documentsPath.appendingPathComponent(filename).path
            try? FileManager.default.removeItem(atPath: filePath)
        }
        modelContext.delete(entry)
    }
}

struct PendingEntryRow: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack(spacing: 15) {
            if let photoPath = entry.photoPath {
                AsyncImage(url: URL(fileURLWithPath: photoPath)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3) )
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.mealType)
                        .font(.headline)
                        // MARK: - 修改：改為 primary (深色模式下為白色)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                
                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("點擊補完份量資訊")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

/// 補完待處理記錄的視圖
struct CompletePendingEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let entry: NutritionEntry
    
    @State private var description: String
    @State private var proteinPortions: Double = 1.0
    @State private var carbPortions: Double = 1.0
    @State private var vegPortions: Double = 1.0
    @State private var fatPortions: Double = 0.5
    @State private var note: String
    
    // MARK: - 新增：暫存熱量變數
    @State private var manualCalories: Double = 0.0
    
    init(entry: NutritionEntry) {
        self.entry = entry
        _description = State(initialValue: entry.entryDescription == "待補完" ? "" : entry.entryDescription)
        _note = State(initialValue: entry.note ?? "")
        
        // 讀取既有的份量資訊（如果有）
        if let protein = entry.proteinPortions {
            _proteinPortions = State(initialValue: protein)
        }
        if let carbs = entry.carbPortions {
            _carbPortions = State(initialValue: carbs)
        }
        if let veg = entry.vegPortions {
            _vegPortions = State(initialValue: veg)
        }
        if let fat = entry.fatPortions {
            _fatPortions = State(initialValue: fat)
        }
        
        // 初始化熱量（如果之前沒設定過，預設為0讓它自動算）
        _manualCalories = State(initialValue: entry.manualCalories ?? 0.0)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let photoPath = entry.photoPath {
                    Section {
                        AsyncImage(url: URL(fileURLWithPath: photoPath)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Section("記錄資訊") {
                    HStack {
                        Text("餐別")
                        Spacer()
                        Text(entry.mealType)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("時間")
                        Spacer()
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("食物描述") {
                    TextField("例如：滷肉飯", text: $description)
                }
                
                Section {
                    HandPortionInputView(
                        proteinPortions: $proteinPortions,
                        carbPortions: $carbPortions,
                        vegPortions: $vegPortions,
                        fatPortions: $fatPortions,
                        calories: $manualCalories // 傳入綁定
                    )
                }
                
                Section("備註") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("補完記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        completeEntry()
                    }
                    .disabled(description.isEmpty)
                }
            }
        }
    }
    
    private func completeEntry() {
        entry.entryDescription = description
        entry.proteinPortions = proteinPortions
        entry.carbPortions = carbPortions
        entry.vegPortions = vegPortions
        entry.fatPortions = fatPortions
        entry.note = note.isEmpty ? nil : note
        
        // MARK: - 寫入熱量
        entry.manualCalories = manualCalories
        
        // 修正：透過 status 計算屬性更新 primitiveStatus 並設為 complete
        entry.status = .complete
        entry.unit = .handPortion
        
        dismiss()
    }
}
