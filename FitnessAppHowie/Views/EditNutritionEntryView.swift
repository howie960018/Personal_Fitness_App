//
//  EditNutritionEntryView.swift
//  FitHowie
//
//  編輯飲食記錄視圖 - 支援日期修改與手掌法則
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditNutritionEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let entry: NutritionEntry
    
    // MARK: - 新增：日期 State
    @State private var date: Date
    
    @State private var mealType: String
    @State private var description: String
    @State private var note: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var existingPhotoFilename: String?
    
    // 模式切換
    @State private var useHandPortion: Bool
    
    // 手掌法則數據
    @State private var proteinPortions: Double
    @State private var carbPortions: Double
    @State private var vegPortions: Double
    @State private var fatPortions: Double
    
    // 傳統模式數據
    @State private var amount: String
    @State private var selectedUnit: NutritionUnit
    
    let mealTypes = ["早餐", "午餐", "晚餐", "點心", "其他"]
    
    init(entry: NutritionEntry) {
        self.entry = entry
        
        // MARK: - 新增：初始化日期
        _date = State(initialValue: entry.timestamp)
        
        _mealType = State(initialValue: entry.mealType)
        _description = State(initialValue: entry.entryDescription)
        _note = State(initialValue: entry.note ?? "")
        _existingPhotoFilename = State(initialValue: entry.photoFilename)
        
        // 判斷模式
        let isHandMode = entry.isHandPortionMode
        _useHandPortion = State(initialValue: isHandMode)
        
        // 手掌法則數據
        _proteinPortions = State(initialValue: entry.proteinPortions ?? 1.0)
        _carbPortions = State(initialValue: entry.carbPortions ?? 1.0)
        _vegPortions = State(initialValue: entry.vegPortions ?? 1.0)
        _fatPortions = State(initialValue: entry.fatPortions ?? 0.5)
        
        // 傳統模式數據
        _amount = State(initialValue: String(entry.amount))
        _selectedUnit = State(initialValue: entry.unit)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 新增：日期選擇器
                Section("記錄資訊") {
                    DatePicker("記錄時間", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("餐別") {
                    Picker("餐別", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                
                Section("內容") {
                    TextField("飲食描述", text: $description)
                }
                
                Section("照片") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else if let existingPhotoFilename,
                                  let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let photoPath = documentsPath.appendingPathComponent(existingPhotoFilename).path
                            if let uiImage = UIImage(contentsOfFile: photoPath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        } else {
                            Label("選擇照片", systemImage: "photo.on.rectangle")
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                    
                    if existingPhotoFilename != nil || photoData != nil {
                        Button(role: .destructive) {
                            existingPhotoFilename = nil
                            photoData = nil
                            selectedPhoto = nil
                        } label: {
                            Label("移除照片", systemImage: "trash")
                        }
                    }
                }
                
                // 模式切換
                Section {
                    Toggle("使用手掌法則估算", isOn: $useHandPortion)
                }
                
                // 份量輸入區
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
                            TextField("份量", text: $amount)
                                .keyboardType(.decimalPad)
                            
                            Picker("單位", selection: $selectedUnit) {
                                ForEach([NutritionUnit.serving, .weight, .calorie], id: \.self) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                
                Section("備註") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("編輯飲食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        saveEntry()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        if useHandPortion {
            return !description.isEmpty
        } else {
            return !description.isEmpty && Double(amount) != nil
        }
    }
    
    private func saveEntry() {
        // MARK: - 修改：更新時間
        entry.timestamp = date
        
        entry.mealType = mealType
        entry.entryDescription = description
        entry.note = note.isEmpty ? nil : note
        
        // 處理照片
        if let photoData {
            if let oldFilename = entry.photoFilename,
               let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let oldPath = documentsPath.appendingPathComponent(oldFilename).path
                try? FileManager.default.removeItem(atPath: oldPath)
            }
            
            let filename = "\(UUID().uuidString).jpg"
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentsPath.appendingPathComponent(filename)
                try? photoData.write(to: fileURL)
                entry.photoFilename = filename
            }
        } else if existingPhotoFilename == nil && entry.photoFilename != nil {
            if let oldFilename = entry.photoFilename,
               let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let oldPath = documentsPath.appendingPathComponent(oldFilename).path
                try? FileManager.default.removeItem(atPath: oldPath)
            }
            entry.photoFilename = nil
        }
        
        // 更新份量數據
        if useHandPortion {
            entry.unit = .handPortion
            entry.proteinPortions = proteinPortions
            entry.carbPortions = carbPortions
            entry.vegPortions = vegPortions
            entry.fatPortions = fatPortions
        } else {
            guard let amountValue = Double(amount) else { return }
            entry.amount = amountValue
            entry.unit = selectedUnit
            entry.proteinPortions = nil
            entry.carbPortions = nil
            entry.vegPortions = nil
            entry.fatPortions = nil
        }
        
        entry.status = .complete
        
        dismiss()
    }
}

#Preview {
    let entry = NutritionEntry(
        mealType: "午餐",
        entryDescription: "雞胸肉沙拉配糙米飯",
        amount: 1.5,
        unit: .serving,
        note: "味道不錯,蛋白質含量高"
    )
    
    return EditNutritionEntryView(entry: entry)
        .modelContainer(for: NutritionEntry.self, inMemory: true)
}
