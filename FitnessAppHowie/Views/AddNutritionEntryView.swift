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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var useHandPortion = true
    
    // 手掌法則變數
    @State private var proteinPortions: Double = 1.0
    @State private var carbPortions: Double = 1.0
    @State private var vegPortions: Double = 1.0
    @State private var fatPortions: Double = 0.5
    
    // 總熱量 (如果是手掌模式由滑桿算，如果是普通模式由下方算)
    @State private var manualCalories: Double = 0.0
    
    // MARK: - 新增：單位熱量變數 (用於普通模式)
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
                            fatPortions: $fatPortions,
                            calories: $manualCalories
                        )
                    }
                } else {
                    // MARK: - 修改：卡路里 x 份數 的輸入介面
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
                            
                            // 這裡讓使用者選單位文字，例如 "份", "顆", "碗"
                            Picker("", selection: $selectedUnit) {
                                Text("份").tag(NutritionUnit.serving)
                                Text("克").tag(NutritionUnit.weight)
                                // 不再需要 .calorie 選項，因為我們是直接算熱量
                            }
                            .labelsHidden()
                        }
                        
                        // 即時顯示計算結果
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
    
    // 輔助計算：單位熱量 * 份數
    private func calculateTotalManualCalories() -> Double {
        let perUnit = Double(caloriesPerUnit) ?? 0
        let count = Double(amount) ?? 0
        return perUnit * count
    }
    
    private var canSave: Bool {
        useHandPortion ? (photoData != nil || !description.isEmpty) : (!description.isEmpty && Double(amount) != nil)
    }
    
    private func quickSavePhoto() {
        guard let photoData else { return }
        let filename = "\(UUID().uuidString).jpg"
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? photoData.write(to: documentsPath.appendingPathComponent(filename))
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
        
        // 決定最終儲存的熱量
        let finalCalories: Double
        if useHandPortion {
            finalCalories = manualCalories
        } else {
            // 普通模式：儲存計算後的總熱量
            finalCalories = calculateTotalManualCalories()
        }
        
        let entry = useHandPortion ?
            NutritionEntry(
                timestamp: date,
                mealType: mealType,
                entryDescription: description.isEmpty ? "外食記錄" : description,
                photoFilename: photoFilename,
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
                photoFilename: photoFilename,
                amount: Double(amount) ?? 0,
                unit: selectedUnit,
                manualCalories: finalCalories, // 儲存總熱量
                note: note.isEmpty ? nil : note,
                status: .complete
            )
        
        modelContext.insert(entry)
        dismiss()
    }
}
