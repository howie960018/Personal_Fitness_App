//
//  PendingNutritionView.swift
//  FitHowie
//
//  待補完飲食記錄視圖 - 支援多張照片
//

import SwiftUI
import SwiftData

struct PendingNutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NutritionEntry.timestamp, order: .reverse) private var allEntries: [NutritionEntry]
    
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
            Text("太棒了!")
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
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            for filename in entry.photoFilenames {
                let filePath = documentsPath.appendingPathComponent(filename).path
                try? FileManager.default.removeItem(atPath: filePath)
            }
            
            if let oldFilename = entry.photoFilename, !entry.photoFilenames.contains(oldFilename) {
                let filePath = documentsPath.appendingPathComponent(oldFilename).path
                try? FileManager.default.removeItem(atPath: filePath)
            }
        }
        modelContext.delete(entry)
    }
}

// MARK: - 修改:支援多張照片的待補完記錄行
struct PendingEntryRow: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack(spacing: 15) {
            // 照片顯示區域
            if !entry.photoURLs.isEmpty {
                if entry.photoURLs.count == 1 {
                    AsyncImage(url: entry.photoURLs[0]) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // 多張照片:顯示網格縮圖
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: entry.photoURLs[0]) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("\(entry.photoURLs.count) 張")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Capsule())
                            .padding(4)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
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
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                
                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // 顯示照片數量提示
                if entry.photoURLs.count > 1 {
                    Text("包含 \(entry.photoURLs.count) 張照片")
                        .font(.caption)
                        .foregroundStyle(.blue)
                } else {
                    Text("點擊補完份量資訊")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
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
    @State private var manualCalories: Double = 0.0
    
    // 用於照片輪播
    @State private var currentPhotoIndex = 0
    
    init(entry: NutritionEntry) {
        self.entry = entry
        _description = State(initialValue: entry.entryDescription == "待補完" ? "" : entry.entryDescription)
        _note = State(initialValue: entry.note ?? "")
        
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
        
        _manualCalories = State(initialValue: entry.manualCalories ?? 0.0)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 修改:支援多張照片輪播
                if !entry.photoURLs.isEmpty {
                    Section {
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
                        .frame(height: 250)
                        .tabViewStyle(.page)
                        .indexViewStyle(.page(backgroundDisplayMode: .always))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if entry.photoURLs.count > 1 {
                            HStack {
                                Spacer()
                                Text("\(currentPhotoIndex + 1) / \(entry.photoURLs.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
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
                    TextField("例如:滷肉飯", text: $description)
                }
                
                Section {
                    HandPortionInputView(
                        proteinPortions: $proteinPortions,
                        carbPortions: $carbPortions,
                        vegPortions: $vegPortions,
                        fatPortions: $fatPortions,
                        calories: $manualCalories
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
        entry.manualCalories = manualCalories
        entry.status = .complete
        entry.unit = .handPortion
        
        dismiss()
    }
}
