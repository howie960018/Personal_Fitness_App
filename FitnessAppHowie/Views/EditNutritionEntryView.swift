import SwiftUI
import SwiftData
import PhotosUI

struct EditNutritionEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let entry: NutritionEntry
    
    @State private var date: Date
    @State private var mealType: String
    @State private var description: String
    @State private var note: String
    
    // MARK: - 修改:支援多張照片
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var newPhotoDataArray: [Data] = [] // 新選擇的照片
    @State private var existingPhotoFilenames: [String] // 既有的照片檔名
    
    @State private var useHandPortion: Bool
    
    @State private var proteinPortions: Double
    @State private var carbPortions: Double
    @State private var vegPortions: Double
    @State private var fatPortions: Double
    
    @State private var manualCalories: Double = 0.0
    @State private var caloriesPerUnit: String = ""
    
    @State private var amount: String
    @State private var selectedUnit: NutritionUnit
    
    let mealTypes = ["早餐", "午餐", "晚餐", "點心", "其他"]
    
    init(entry: NutritionEntry) {
        self.entry = entry
        
        _date = State(initialValue: entry.timestamp)
        _mealType = State(initialValue: entry.mealType)
        _description = State(initialValue: entry.entryDescription)
        _note = State(initialValue: entry.note ?? "")
        
        // 載入既有照片
        _existingPhotoFilenames = State(initialValue: entry.photoFilenames)
        
        let isHandMode = entry.isHandPortionMode
        _useHandPortion = State(initialValue: isHandMode)
        
        _proteinPortions = State(initialValue: entry.proteinPortions ?? 1.0)
        _carbPortions = State(initialValue: entry.carbPortions ?? 1.0)
        _vegPortions = State(initialValue: entry.vegPortions ?? 1.0)
        _fatPortions = State(initialValue: entry.fatPortions ?? 0.5)
        
        let totalCals = entry.manualCalories ?? entry.estimatedCalories
        _manualCalories = State(initialValue: totalCals)
        
        let amt = entry.amount
        _amount = State(initialValue: String(amt))
        _selectedUnit = State(initialValue: entry.unit)
        
        if !isHandMode && amt > 0 {
            let perUnit = totalCals / amt
            if perUnit.truncatingRemainder(dividingBy: 1) == 0 {
                _caloriesPerUnit = State(initialValue: String(format: "%.0f", perUnit))
            } else {
                _caloriesPerUnit = State(initialValue: String(format: "%.1f", perUnit))
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
                
                // MARK: - 修改:支援多張照片編輯
                Section("照片管理 (可選多張)") {
                    // 顯示既有照片
                    if !existingPhotoFilenames.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("目前照片 (\(existingPhotoFilenames.count) 張)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(existingPhotoFilenames.enumerated()), id: \.offset) { index, filename in
                                        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                            let photoPath = documentsPath.appendingPathComponent(filename).path
                                            if let uiImage = UIImage(contentsOfFile: photoPath) {
                                                ZStack(alignment: .topTrailing) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 120, height: 120)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    
                                                    Button {
                                                        existingPhotoFilenames.remove(at: index)
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundStyle(.white)
                                                            .background(Circle().fill(Color.red))
                                                    }
                                                    .padding(4)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // 新增照片
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                        Label(newPhotoDataArray.isEmpty ? "新增照片" : "已選擇 \(newPhotoDataArray.count) 張新照片",
                              systemImage: "photo.badge.plus")
                    }
                    .onChange(of: selectedPhotos) { _, newPhotos in
                        Task {
                            newPhotoDataArray.removeAll()
                            for photo in newPhotos {
                                if let data = try? await photo.loadTransferable(type: Data.self) {
                                    newPhotoDataArray.append(data)
                                }
                            }
                        }
                    }
                    
                    // 顯示新選照片
                    if !newPhotoDataArray.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(newPhotoDataArray.enumerated()), id: \.offset) { index, data in
                                    if let uiImage = UIImage(data: data) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            
                                            Button {
                                                newPhotoDataArray.remove(at: index)
                                                selectedPhotos.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white)
                                                    .background(Circle().fill(Color.red))
                                            }
                                            .padding(4)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Button("清除新選照片", role: .destructive) {
                            newPhotoDataArray.removeAll()
                            selectedPhotos.removeAll()
                        }
                    }
                    
                    if !existingPhotoFilenames.isEmpty || !newPhotoDataArray.isEmpty {
                        let totalCount = existingPhotoFilenames.count + newPhotoDataArray.count
                        Text("總計將有 \(totalCount) 張照片")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                
                Section {
                    Toggle("使用手掌法則估算", isOn: $useHandPortion)
                }
                
                if useHandPortion {
                    Section {
                        HandPortionInputView(
                            proteinPortions: $proteinPortions,
                            carbPortions: $carbPortions,
                            vegPortions: $vegPortions,
                            fatPortions: $fatPortions,
                            calories: $manualCalories
                        )
                    }
                } else {
                    Section("精確計算") {
                        HStack {
                            Text("單位熱量")
                            Spacer()
                            TextField("0", text: $caloriesPerUnit)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("kcal")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("數量/份數")
                            Spacer()
                            TextField("1", text: $amount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            
                            Picker("", selection: $selectedUnit) {
                                Text("份").tag(NutritionUnit.serving)
                                Text("克").tag(NutritionUnit.weight)
                            }
                            .labelsHidden()
                        }
                        
                        HStack {
                            Text("總熱量")
                                .bold()
                            Spacer()
                            let total = calculateTotalManualCalories()
                            Text("\(Int(total)) kcal")
                                .foregroundStyle(.blue)
                                .bold()
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
    
    private func calculateTotalManualCalories() -> Double {
        let perUnit = Double(caloriesPerUnit) ?? 0
        let count = Double(amount) ?? 0
        return perUnit * count
    }
    
    private var canSave: Bool {
        if useHandPortion {
            return !description.isEmpty
        } else {
            return !description.isEmpty && Double(amount) != nil
        }
    }
    
    // MARK: - 修改:儲存多張照片
    private func saveEntry() {
        entry.timestamp = date
        entry.mealType = mealType
        entry.entryDescription = description
        entry.note = note.isEmpty ? nil : note
        
        // 處理照片:刪除舊的 + 新增新的
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        // 刪除被移除的舊照片檔案
        for oldFilename in entry.photoFilenames {
            if !existingPhotoFilenames.contains(oldFilename) {
                let oldPath = documentsPath.appendingPathComponent(oldFilename).path
                try? FileManager.default.removeItem(atPath: oldPath)
            }
        }
        
        // 儲存新照片
        var newFilenames: [String] = []
        for data in newPhotoDataArray {
            let filename = "\(UUID().uuidString).jpg"
            let fileURL = documentsPath.appendingPathComponent(filename)
            if (try? data.write(to: fileURL)) != nil {
                newFilenames.append(filename)
            }
        }
        
        // 更新照片陣列
        entry.photoFilenames = existingPhotoFilenames + newFilenames
        
        // 更新其他資料
        if useHandPortion {
            entry.unit = .handPortion
            entry.proteinPortions = proteinPortions
            entry.carbPortions = carbPortions
            entry.vegPortions = vegPortions
            entry.fatPortions = fatPortions
            entry.manualCalories = manualCalories
        } else {
            guard let amountValue = Double(amount) else { return }
            entry.amount = amountValue
            entry.unit = selectedUnit
            entry.proteinPortions = nil
            entry.carbPortions = nil
            entry.vegPortions = nil
            entry.fatPortions = nil
            entry.manualCalories = calculateTotalManualCalories()
        }
        
        entry.status = .complete
        dismiss()
    }
}
