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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var existingPhotoFilename: String?
    
    @State private var useHandPortion: Bool
    
    @State private var proteinPortions: Double
    @State private var carbPortions: Double
    @State private var vegPortions: Double
    @State private var fatPortions: Double
    
    // 手掌模式用的總熱量
    @State private var manualCalories: Double = 0.0
    
    // MARK: - 新增：普通模式用的單位熱量
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
        _existingPhotoFilename = State(initialValue: entry.photoFilename)
        
        let isHandMode = entry.isHandPortionMode
        _useHandPortion = State(initialValue: isHandMode)
        
        _proteinPortions = State(initialValue: entry.proteinPortions ?? 1.0)
        _carbPortions = State(initialValue: entry.carbPortions ?? 1.0)
        _vegPortions = State(initialValue: entry.vegPortions ?? 1.0)
        _fatPortions = State(initialValue: entry.fatPortions ?? 0.5)
        
        // 初始化總熱量
        let totalCals = entry.manualCalories ?? entry.estimatedCalories
        _manualCalories = State(initialValue: totalCals)
        
        // 傳統模式數據
        let amt = entry.amount
        _amount = State(initialValue: String(amt))
        _selectedUnit = State(initialValue: entry.unit)
        
        // MARK: - 初始化單位熱量
        // 如果不是手掌模式，試著反推單位熱量 (總熱量 / 份數)
        if !isHandMode && amt > 0 {
            let perUnit = totalCals / amt
            // 如果是整數就顯示整數，不然顯示小數
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
                    // MARK: - 修改：卡路里 x 份數 輸入
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
                        
                        // 計算並顯示結果
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
    
    private func saveEntry() {
        entry.timestamp = date
        entry.mealType = mealType
        entry.entryDescription = description
        entry.note = note.isEmpty ? nil : note
        
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
            
            // 儲存計算後的總熱量
            entry.manualCalories = calculateTotalManualCalories()
        }
        
        entry.status = .complete
        dismiss()
    }
}
