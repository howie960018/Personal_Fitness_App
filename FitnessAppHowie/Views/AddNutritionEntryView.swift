import SwiftUI
import SwiftData
import PhotosUI

struct AddNutritionEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    @State private var mealType = "午餐"
    @State private var description = ""
    @State private var note = ""
    
    // MARK: - 修改：支援多張照片
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoDataArray: [Data] = []
    
    @State private var useHandPortion = true
    
    // 手掌法則變數
    @State private var proteinPortions: Double = 1.0
    @State private var carbPortions: Double = 1.0
    @State private var vegPortions: Double = 1.0
    @State private var fatPortions: Double = 0.5
    
    // 總熱量
    @State private var manualCalories: Double = 0.0
    
    // 單位熱量變數 (用於普通模式)
    @State private var caloriesPerUnit: String = ""
    
    @State private var amount = ""
    @State private var selectedUnit: NutritionUnit = .serving
    
    let mealTypes = ["早餐", "午餐", "晚餐", "點心", "其他"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("日期與時間") {
                    DatePicker("記錄時間", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("餐別") {
                    Picker("餐別", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - 修改：支援多張照片選擇與顯示
                Section("食物照片 (可選多張)") {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                        if photoDataArray.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.blue)
                                Text("選擇照片")
                                    .font(.headline)
                                Text("可一次選擇多張照片 (最多10張)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("已選擇 \(photoDataArray.count) 張照片")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Array(photoDataArray.enumerated()), id: \.offset) { index, data in
                                            if let uiImage = UIImage(data: data) {
                                                ZStack(alignment: .topTrailing) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 120, height: 120)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    
                                                    // 刪除按鈕
                                                    Button {
                                                        photoDataArray.remove(at: index)
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
                            }
                        }
                    }
                    .onChange(of: selectedPhotos) { _, newPhotos in
                        Task {
                            photoDataArray.removeAll()
                            for photo in newPhotos {
                                if let data = try? await photo.loadTransferable(type: Data.self) {
                                    photoDataArray.append(data)
                                }
                            }
                        }
                    }
                    
                    if !photoDataArray.isEmpty {
                        Button("清除所有照片", role: .destructive) {
                            selectedPhotos.removeAll()
                            photoDataArray.removeAll()
                        }
                    }
                }
                
                Section {
                    Button { quickSavePhoto() } label: {
                        Label("只儲存照片，稍後補完", systemImage: "clock.badge.checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(photoDataArray.isEmpty)
                }
                
                Section("內容") {
                    TextField("食物描述", text: $description)
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
                    TextEditor(text: $note).frame(minHeight: 80)
                }
            }
            .navigationTitle("新增飲食")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { saveEntry() }.disabled(!canSave)
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
        useHandPortion ? (!photoDataArray.isEmpty || !description.isEmpty) : (!description.isEmpty && Double(amount) != nil)
    }
    
    // MARK: - 修改：儲存多張照片的快速模式
    private func quickSavePhoto() {
        guard !photoDataArray.isEmpty else { return }
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        var savedFilenames: [String] = []
        
        for data in photoDataArray {
            let filename = "\(UUID().uuidString).jpg"
            let fileURL = documentsPath.appendingPathComponent(filename)
            if (try? data.write(to: fileURL)) != nil {
                savedFilenames.append(filename)
            }
        }
        
        let entry = NutritionEntry(
            timestamp: date,
            mealType: mealType,
            entryDescription: "待補完",
            photoFilenames: savedFilenames,
            status: .pending
        )
        
        modelContext.insert(entry)
        dismiss()
    }
    
    // MARK: - 修改：儲存多張照片
    private func saveEntry() {
        var savedFilenames: [String] = []
        
        if !photoDataArray.isEmpty {
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            for data in photoDataArray {
                let filename = "\(UUID().uuidString).jpg"
                let fileURL = documentsPath.appendingPathComponent(filename)
                if (try? data.write(to: fileURL)) != nil {
                    savedFilenames.append(filename)
                }
            }
        }
        
        let finalCalories: Double
        if useHandPortion {
            finalCalories = manualCalories
        } else {
            finalCalories = calculateTotalManualCalories()
        }
        
        let entry = useHandPortion ?
            NutritionEntry(
                timestamp: date,
                mealType: mealType,
                entryDescription: description.isEmpty ? "外食記錄" : description,
                photoFilenames: savedFilenames,
                unit: .handPortion,
                proteinPortions: proteinPortions,
                carbPortions: carbPortions,
                vegPortions: vegPortions,
                fatPortions: fatPortions,
                manualCalories: finalCalories,
                note: note.isEmpty ? nil : note,
                status: .complete
            ) :
            NutritionEntry(
                timestamp: date,
                mealType: mealType,
                entryDescription: description,
                photoFilenames: savedFilenames,
                amount: Double(amount) ?? 0,
                unit: selectedUnit,
                manualCalories: finalCalories,
                note: note.isEmpty ? nil : note,
                status: .complete
            )
        
        modelContext.insert(entry)
        dismiss()
    }
}
