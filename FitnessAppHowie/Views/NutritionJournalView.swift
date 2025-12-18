import SwiftUI
import SwiftData
import PhotosUI

struct NutritionJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NutritionEntry.timestamp, order: .reverse) private var allEntries: [NutritionEntry]
    
    @State private var showingAddEntry = false
    @State private var showingPendingList = false
    @State private var entryToEdit: NutritionEntry?
    
    // 修正：手動過濾並處理 nil 的舊資料
    private var pendingCount: Int {
        allEntries.filter { ($0.primitiveStatus ?? .complete) == .pending }.count
    }
    
    // 修正：只顯示已完成的記錄，並處理舊資料相容性
    private var completedEntries: [NutritionEntry] {
        allEntries.filter { ($0.primitiveStatus ?? .complete) == .complete }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if allEntries.isEmpty {
                    emptyStateView
                } else {
                    nutritionListView
                }
            }
            .navigationTitle("飲食記錄")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if pendingCount > 0 {
                        Button {
                            showingPendingList = true
                        } label: {
                            Label("\(pendingCount) 筆待補完", systemImage: "clock.badge.exclamationmark")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddNutritionEntryView() // 確保此視圖在下方有定義
            }
            .sheet(isPresented: $showingPendingList) {
                PendingNutritionView()
            }
            .sheet(item: $entryToEdit) { entry in
                EditNutritionEntryView(entry: entry)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("尚無飲食記錄")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                Button("開始記錄飲食") {
                    showingAddEntry = true
                }
                .buttonStyle(.borderedProminent)
                
                Text("提示：外食時可先拍照，稍後再補完份量")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private var nutritionListView: some View {
        List {
            if pendingCount > 0 {
                Section {
                    Button {
                        showingPendingList = true
                    } label: {
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark")
                                .foregroundStyle(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("有 \(pendingCount) 筆記錄待補完")
                                    .font(.subheadline)
                                    .bold()
                                Text("點擊前往補完份量資訊")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .tint(.primary)
                }
                .listRowBackground(Color.orange.opacity(0.1))
            }
            
            ForEach(completedEntries) { entry in
                NavigationLink {
                    NutritionDetailView(entry: entry)
                } label: {
                    NutritionRowView(entry: entry) // 確保此視圖在下方有定義
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteEntry(entry)
                    } label: {
                        Label("刪除", systemImage: "trash")
                    }
                    
                    Button {
                        entryToEdit = entry
                    } label: {
                        Label("編輯", systemImage: "pencil")
                    }
                    .tint(.blue)
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


// MARK: - NutritionRowView (已簡化：只顯示縮圖與基本資訊)

struct NutritionRowView: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // 1. 縮圖 (保持不變)
            if let photoPath = entry.photoPath {
                AsyncImage(url: URL(fileURLWithPath: photoPath)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // 如果沒有照片，顯示一個簡單的佔位符
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.secondary)
                    }
            }
            
            // 2. 文字資訊 (移除 MacroTag，只留總結)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.mealType)
                        .font(.headline)
                        .foregroundStyle(.orange)
                    
                    Spacer()
                    
                    // 顯示時間
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    // 顯示描述 (例如：雞胸肉便當)
                    Text(entry.entryDescription.isEmpty ? "無描述" : entry.entryDescription)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // 僅顯示總熱量估算 (作為一個簡單的參考指標)
                    // 如果你連熱量都不想看，可以把下面這行刪除
                    if entry.estimatedCalories > 0 {
                        Text("\(Int(entry.estimatedCalories)) kcal")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .bold()
                    }
                }
            }
        }
        .padding(.vertical, 6) // 稍微增加一點垂直間距讓視覺更舒適
    }
}
// MARK: - AddNutritionEntryView
//
//  AddNutritionEntryView.swift
//  FitHowie
//
//  新增飲食視圖 - 支援日期選擇與手掌法則
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddNutritionEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 新增：日期變數
    @State private var date = Date()
    
    @State private var mealType = "午餐"
    @State private var description = ""
    @State private var note = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var useHandPortion = true
    
    @State private var proteinPortions: Double = 1.0
    @State private var carbPortions: Double = 1.0
    @State private var vegPortions: Double = 1.0
    @State private var fatPortions: Double = 0.5
    
    @State private var amount = ""
    @State private var selectedUnit: NutritionUnit = .serving
    
    let mealTypes = ["早餐", "午餐", "晚餐", "點心", "其他"]
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 新增：日期選擇區塊
                Section("日期與時間") {
                    DatePicker("記錄時間", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("餐別") {
                    Picker("餐別", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("食物照片") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill").font(.system(size: 50)).foregroundStyle(.blue)
                                Text("拍攝食物").font(.headline)
                                Text("點擊拍照或選擇相簿").font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(height: 150).frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground)).cornerRadius(12)
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                }
                
                Section {
                    Button { quickSavePhoto() } label: {
                        Label("只儲存照片，稍後補完", systemImage: "clock.badge.checkmark").frame(maxWidth: .infinity)
                    }
                    .disabled(photoData == nil)
                }
                
                Section("內容") { TextField("食物描述", text: $description) }
                
                Section { Toggle("使用手掌法則估算", isOn: $useHandPortion) }
                
                if useHandPortion {
                    Section {
                        HandPortionInputView(
                            proteinPortions: $proteinPortions,
                            carbPortions: $carbPortions,
                            vegPortions: $vegPortions,
                            fatPortions: $fatPortions
                        )
                    }
                } else {
                    Section("份量") {
                        HStack {
                            TextField("份量", text: $amount).keyboardType(.decimalPad)
                            Picker("單位", selection: $selectedUnit) {
                                ForEach([NutritionUnit.serving, .weight, .calorie], id: \.self) { Text($0.rawValue).tag($0) }
                            }
                        }
                    }
                }
                
                Section("備註") { TextEditor(text: $note).frame(minHeight: 80) }
            }
            .navigationTitle("新增飲食")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { saveEntry() }.disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        useHandPortion ? (photoData != nil || !description.isEmpty) : (!description.isEmpty && Double(amount) != nil)
    }
    
    private func quickSavePhoto() {
        guard let photoData else { return }
        let filename = "\(UUID().uuidString).jpg"
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? photoData.write(to: documentsPath.appendingPathComponent(filename))
            // MARK: - 修改：傳入 date
            let entry = NutritionEntry(timestamp: date, mealType: mealType, entryDescription: "待補完", photoFilename: filename, status: .pending)
            modelContext.insert(entry)
            dismiss()
        }
    }
    
    private func saveEntry() {
        var photoFilename: String?
        if let photoData {
            let filename = "\(UUID().uuidString).jpg"
            if let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                try? photoData.write(to: path.appendingPathComponent(filename))
                photoFilename = filename
            }
        }
        
        // MARK: - 修改：傳入 date
        let entry = useHandPortion ?
            NutritionEntry(timestamp: date, mealType: mealType, entryDescription: description.isEmpty ? "外食記錄" : description, photoFilename: photoFilename, unit: .handPortion, proteinPortions: proteinPortions, carbPortions: carbPortions, vegPortions: vegPortions, fatPortions: fatPortions, note: note.isEmpty ? nil : note, status: .complete) :
            NutritionEntry(timestamp: date, mealType: mealType, entryDescription: description, photoFilename: photoFilename, amount: Double(amount) ?? 0, unit: selectedUnit, note: note.isEmpty ? nil : note, status: .complete)
        
        modelContext.insert(entry)
        dismiss()
    }
}
