////
////  AddWorkoutView.swift
////  FitHowie
////
////  新增訓練視圖 - 完整版
////  包含 ExerciseSetData, SetData, ExerciseDetailEditor, SetConfigurationCard
////
//
//import SwiftUI
//import SwiftData
//import PhotosUI
//import AVKit
//
//struct AddWorkoutView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Environment(\.dismiss) private var dismiss
//    
//    // MARK: - 狀態變數
//    @State private var date = Date()
//    @State private var selectedType: TrainingType = .anaerobic
//    @State private var durationMinutes = ""
//    @State private var note = ""
//    @State private var exercises: [ExerciseSetData] = []
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                // 日期選擇區塊
//                Section("日期與時間") {
//                    DatePicker("開始時間", selection: $date, displayedComponents: [.date, .hourAndMinute])
//                }
//                
//                // 訓練類型
//                Section {
//                    Picker("訓練類型", selection: $selectedType) {
//                        ForEach(TrainingType.allCases, id: \.self) { type in
//                            Text(type.rawValue).tag(type)
//                        }
//                    }
//                    .pickerStyle(.segmented)
//                }
//                
//                // 訓練時長
//                Section("訓練資訊") {
//                    HStack {
//                        TextField("訓練時長", text: $durationMinutes)
//                            .keyboardType(.numberPad)
//                        Text("分鐘")
//                            .foregroundStyle(.secondary)
//                    }
//                }
//                
//                // 動作列表 (僅無氧訓練顯示)
//                if selectedType == .anaerobic {
//                    Section {
//                        // 使用 $exercises 綁定，支援直接編輯
//                        ForEach($exercises) { $exerciseData in
//                            NavigationLink {
//                                // 進入單一動作編輯
//                                ExerciseDetailEditor(exercise: $exerciseData)
//                            } label: {
//                                VStack(alignment: .leading, spacing: 6) {
//                                    HStack {
//                                        Text(exerciseData.exerciseName.isEmpty ? "未命名動作" : exerciseData.exerciseName)
//                                            .font(.headline)
//                                        Spacer()
//                                        // 如果有媒體，顯示一個小圖示
//                                        if exerciseData.mediaData != nil || exerciseData.existingFilename != nil {
//                                            Image(systemName: (exerciseData.mediaType ?? "photo") == "video" ? "video.fill" : "photo.fill")
//                                                .foregroundStyle(.blue)
//                                        }
//                                    }
//                                    
//                                    HStack {
//                                        Text("\(exerciseData.muscleGroup.rawValue) • \(exerciseData.exerciseType.rawValue)")
//                                            .font(.caption)
//                                            .foregroundStyle(.secondary)
//                                        Spacer()
//                                        if !exerciseData.sets.isEmpty {
//                                            let totalSets = exerciseData.sets.reduce(0) { $0 + $1.numberOfSets }
//                                            Text("\(totalSets) 組")
//                                                .font(.caption)
//                                                .foregroundStyle(.blue)
//                                        }
//                                    }
//                                    if let note = exerciseData.note, !note.isEmpty {
//                                        Text(note)
//                                            .font(.caption2)
//                                            .foregroundStyle(.orange)
//                                            .lineLimit(1)
//                                    }
//                                }
//                            }
//                        }
//                        .onDelete { indexSet in
//                            exercises.remove(atOffsets: indexSet)
//                        }
//                        .onMove { from, to in
//                            exercises.move(fromOffsets: from, toOffset: to)
//                        }
//                        
//                        Button {
//                            exercises.append(ExerciseSetData())
//                        } label: {
//                            Label("新增動作", systemImage: "plus.circle.fill")
//                        }
//                    } header: {
//                        HStack {
//                            Text("動作列表")
//                            Spacer()
//                            if !exercises.isEmpty {
//                                Text("長按可拖曳排序")
//                                    .font(.caption)
//                                    .foregroundStyle(.secondary)
//                            }
//                        }
//                    }
//                }
//                
//                // 備註
//                Section("備註") {
//                    TextEditor(text: $note)
//                        .frame(minHeight: 100)
//                }
//            }
//            .navigationTitle("新增訓練")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("取消") {
//                        dismiss()
//                    }
//                }
//                // 加入 EditButton 讓排序更方便
//                ToolbarItem(placement: .topBarLeading) {
//                    EditButton()
//                }
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("儲存") {
//                        saveWorkout()
//                    }
//                    .disabled(!canSave)
//                }
//            }
//        }
//    }
//    
//    // MARK: - 邏輯處理
//    
//    private var canSave: Bool {
//        guard let duration = Int(durationMinutes), duration > 0 else { return false }
//        if selectedType == .anaerobic {
//            return !exercises.isEmpty && exercises.allSatisfy { !$0.exerciseName.isEmpty && !$0.sets.isEmpty }
//        }
//        return true
//    }
//    
//    private func saveWorkout() {
//            guard let duration = Int(durationMinutes) else { return }
//            
//            let workout = WorkoutRecord(
//                timestamp: date,
//                trainingType: selectedType,
//                durationMinutes: duration,
//                note: note.isEmpty ? nil : note
//            )
//            
//            if selectedType == .anaerobic {
//                // MARK: - 修改：使用 enumerated() 取得索引 (index)
//                for (index, exerciseData) in exercises.enumerated() {
//                    
//                    // 1. 轉換組數
//                    var allSets: [SetEntry] = []
//                    for setData in exerciseData.sets {
//                        let weightInKg = exerciseData.weightUnit.toKg(setData.weight)
//                        for _ in 0..<setData.numberOfSets {
//                            allSets.append(SetEntry(weight: weightInKg, reps: setData.reps))
//                        }
//                    }
//                    
//                    // 2. 處理媒體
//                    var filename: String?
//                    if let data = exerciseData.mediaData, let type = exerciseData.mediaType {
//                        let ext = (type == "video") ? "mov" : "jpg"
//                        filename = MediaHelper.saveMedia(data: data, extensionName: ext)
//                    }
//                    
//                    // 3. 建立 ExerciseSet (傳入 orderIndex)
//                    let exercise = ExerciseSet(
//                        exerciseName: exerciseData.exerciseName,
//                        exerciseType: exerciseData.exerciseType,
//                        muscleGroup: exerciseData.muscleGroup,
//                        sets: allSets,
//                        note: exerciseData.note?.isEmpty == false ? exerciseData.note : nil,
//                        mediaFilename: filename,
//                        mediaType: exerciseData.mediaType,
//                        orderIndex: index // 👈 關鍵：把目前的順序存進去 (0, 1, 2...)
//                    )
//                    workout.exerciseDetails.append(exercise)
//                }
//            }
//            
//            modelContext.insert(workout)
//            dismiss()
//        }
//}
//
//// MARK: - 共用資料結構 (EditWorkoutView 也會用到)
//
///// 用於編輯的動作數據結構
//struct ExerciseSetData: Identifiable {
//    let id = UUID()
//    
//    var exerciseName: String = ""
//    var exerciseType: ExerciseType = .freeWeight
//    var muscleGroup: MuscleGroup = .chest
//    var weightUnit: WeightUnit = .kg
//    var sets: [SetData] = []
//    var note: String? = nil
//    
//    // 媒體暫存
//    var mediaData: Data? = nil
//    var mediaType: String? = nil
//    var existingFilename: String? = nil // 用於編輯時記錄舊檔名
//}
//
///// 用於編輯的組數數據結構
//struct SetData: Identifiable {
//    let id = UUID()
//    var weight: Double = 20
//    var reps: Int = 10
//    var numberOfSets: Int = 3
//}
//
//// MARK: - 動作詳細編輯器 (Sub-View)
//
//struct ExerciseDetailEditor: View {
//    @Binding var exercise: ExerciseSetData
//    @State private var isCustomExercise = false
//    
//    // 媒體選擇器狀態
//    @State private var selectedItem: PhotosPickerItem?
//    
//    // 使用外部定義的 ExerciseLibrary
//    private var exerciseOptions: [String] {
//        ExerciseLibrary.exercises(for: exercise.muscleGroup, exerciseType: exercise.exerciseType)
//    }
//    
//    var body: some View {
//        Form {
//            Section("動作資訊") {
//                Picker("訓練類型", selection: $exercise.exerciseType) {
//                    ForEach(ExerciseType.allCases, id: \.self) { type in
//                        Text(type.rawValue).tag(type)
//                    }
//                }
//                .onChange(of: exercise.exerciseType) { _, _ in
//                    exercise.exerciseName = ""
//                    isCustomExercise = false
//                }
//                
//                Picker("目標部位", selection: $exercise.muscleGroup) {
//                    ForEach(MuscleGroup.allCases, id: \.self) { group in
//                        Text(group.rawValue).tag(group)
//                    }
//                }
//                .onChange(of: exercise.muscleGroup) { _, _ in
//                    exercise.exerciseName = ""
//                    isCustomExercise = false
//                }
//                
//                // 動作名稱選擇邏輯
//                if isCustomExercise {
//                    HStack {
//                        TextField("動作名稱", text: $exercise.exerciseName)
//                        Button("選擇") {
//                            isCustomExercise = false
//                            exercise.exerciseName = ""
//                        }
//                        .foregroundStyle(.blue)
//                    }
//                } else {
//                    Picker("動作名稱", selection: $exercise.exerciseName) {
//                        Text("請選擇").tag("")
//                        ForEach(exerciseOptions, id: \.self) { option in
//                            Text(option).tag(option)
//                        }
//                        Text("其他/自訂").tag("其他")
//                    }
//                    .onChange(of: exercise.exerciseName) { _, newValue in
//                        if newValue == "其他" {
//                            isCustomExercise = true
//                            exercise.exerciseName = ""
//                        }
//                    }
//                }
//                
//                Picker("重量單位", selection: $exercise.weightUnit) {
//                    ForEach(WeightUnit.allCases, id: \.self) { unit in
//                        Text(unit.rawValue).tag(unit)
//                    }
//                }
//                .pickerStyle(.segmented)
//            }
//            
//            // 動作影像紀錄
//            Section("動作影像 (PR/姿勢檢查)") {
//                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
//                    // 1. 優先顯示新選擇的資料
//                    if let data = exercise.mediaData, let type = exercise.mediaType {
//                        if type == "photo", let uiImage = UIImage(data: data) {
//                            Image(uiImage: uiImage)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 200)
//                                .cornerRadius(8)
//                        } else {
//                            ZStack {
//                                Color.black.frame(height: 200).cornerRadius(8)
//                                Image(systemName: "play.circle.fill")
//                                    .font(.largeTitle)
//                                    .foregroundStyle(.white)
//                                Text("新影片已選取")
//                                    .foregroundStyle(.white)
//                                    .padding(.top, 40)
//                            }
//                        }
//                    }
//                    // 2. 顯示舊檔案 (編輯模式用)
//                    else if let filename = exercise.existingFilename, let url = getURL(filename: filename) {
//                        if exercise.mediaType == "video" {
//                             ZStack {
//                                 Color.black.frame(height: 200).cornerRadius(8)
//                                 Image(systemName: "play.circle.fill")
//                                     .font(.largeTitle)
//                                     .foregroundStyle(.white)
//                                 Text("已儲存的影片")
//                                     .foregroundStyle(.white)
//                                     .padding(.top, 40)
//                             }
//                        } else {
//                            AsyncImage(url: url) { img in
//                                img.resizable().scaledToFit()
//                            } placeholder: {
//                                ProgressView()
//                            }
//                            .frame(height: 200)
//                            .cornerRadius(8)
//                        }
//                    }
//                    // 3. 無資料
//                    else {
//                        Label("上傳照片或影片", systemImage: "camera")
//                    }
//                }
//                .onChange(of: selectedItem) { _, newItem in
//                    loadMedia(from: newItem)
//                }
//                
//                if exercise.mediaData != nil || exercise.existingFilename != nil {
//                    Button("移除影像", role: .destructive) {
//                        selectedItem = nil
//                        exercise.mediaData = nil
//                        exercise.existingFilename = nil
//                        exercise.mediaType = nil
//                    }
//                }
//            }
//            
//            Section {
//                ForEach($exercise.sets) { $set in
//                    SetConfigurationCard(set: $set, weightUnit: exercise.weightUnit)
//                }
//                .onDelete { indexSet in
//                    exercise.sets.remove(atOffsets: indexSet)
//                }
//                
//                Button {
//                    exercise.sets.append(SetData())
//                } label: {
//                    Label("新增訓練配置", systemImage: "plus.circle.fill")
//                }
//            } header: {
//                Text("訓練配置")
//            } footer: {
//                if !exercise.sets.isEmpty {
//                    let totalVolume = exercise.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps) * Double($1.numberOfSets)) }
//                    let volumeInKg = exercise.weightUnit.toKg(totalVolume)
//                    
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("總訓練量: \(String(format: "%.1f", totalVolume)) \(exercise.weightUnit.shortName)")
//                            .font(.caption)
//                            .fontWeight(.semibold)
//                        
//                        if exercise.weightUnit == .lb {
//                            Text("(約 \(String(format: "%.1f", volumeInKg)) kg)")
//                                .font(.caption2)
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                 }
//            }
//            
//            Section("備註") {
//                TextEditor(text: Binding(
//                    get: { exercise.note ?? "" },
//                    set: { exercise.note = $0.isEmpty ? nil : $0 }
//                ))
//                .frame(minHeight: 80)
//            }
//        }
//        .navigationTitle("編輯動作")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//    
//    // 讀取媒體邏輯
//    private func loadMedia(from item: PhotosPickerItem?) {
//        guard let item = item else { return }
//        Task {
//            if let movie = try? await item.loadTransferable(type: Data.self),
//               item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
//                await MainActor.run {
//                    exercise.mediaData = movie
//                    exercise.mediaType = "video"
//                }
//                return
//            }
//            if let data = try? await item.loadTransferable(type: Data.self) {
//                await MainActor.run {
//                    exercise.mediaData = data
//                    exercise.mediaType = "photo"
//                }
//            }
//        }
//    }
//    
//    private func getURL(filename: String) -> URL? {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename)
//    }
//}
//
//// MARK: - 單組配置卡片 (Sub-View)
//
//struct SetConfigurationCard: View {
//    @Binding var set: SetData
//    let weightUnit: WeightUnit
//    
//    private var weightStep: Double {
//        weightUnit == .kg ? 2.5 : 5.0
//    }
//    
//    var body: some View {
//        VStack(spacing: 15) {
//            // 重量
//            VStack(alignment: .leading, spacing: 8) {
//                HStack {
//                    Text("重量")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                    Spacer()
//                    Text(String(format: "%.1f", set.weight))
//                        .font(.headline)
//                        .foregroundStyle(.blue)
//                    Text(weightUnit.shortName)
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//                Slider(value: $set.weight, in: 0...200, step: weightStep)
//                    .tint(.blue)
//            }
//            Divider()
//            
//            // 次數
//            VStack(alignment: .leading, spacing: 8) {
//                HStack {
//                    Text("次數")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                    Spacer()
//                    Text("\(set.reps)")
//                        .font(.headline)
//                        .foregroundStyle(.green)
//                    Text("下")
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//                Slider(value: Binding(
//                    get: { Double(set.reps) },
//                    set: { set.reps = Int($0) }
//                ), in: 1...50, step: 1.0)
//                .tint(.green)
//            }
//            Divider()
//            
//            // 組數
//            VStack(alignment: .leading, spacing: 8) {
//                HStack {
//                    Text("組數")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                    Spacer()
//                    Text("\(set.numberOfSets)")
//                        .font(.headline)
//                        .foregroundStyle(.orange)
//                    Text("組")
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//                Slider(value: Binding(
//                    get: { Double(set.numberOfSets) },
//                    set: { set.numberOfSets = Int($0) }
//                ), in: 1...10, step: 1.0)
//                .tint(.orange)
//            }
//            
//            // 訓練量統計
//            VStack(spacing: 4) {
//                Divider()
//                HStack {
//                    Text("單組訓練量:")
//                        .font(.caption2)
//                        .foregroundStyle(.secondary)
//                    Spacer()
//                    let singleSetVolume = set.weight * Double(set.reps)
//                    Text("\(String(format: "%.1f", singleSetVolume)) \(weightUnit.shortName)")
//                        .font(.caption)
//                        .foregroundStyle(.orange)
//                }
//                HStack {
//                    Text("總訓練量 (\(set.numberOfSets) 組):")
//                        .font(.caption2)
//                        .foregroundStyle(.secondary)
//                    Spacer()
//                    let totalVolume = set.weight * Double(set.reps) * Double(set.numberOfSets)
//                    Text("\(String(format: "%.1f", totalVolume)) \(weightUnit.shortName)")
//                        .font(.caption)
//                        .fontWeight(.semibold)
//                        .foregroundStyle(.blue)
//                }
//            }
//        }
//        .padding(.vertical, 12)
//        .padding(.horizontal, 8)
//        .background(Color(.systemGray6))
//        .cornerRadius(12)
//    }
//}

//
//  AddWorkoutView.swift
//  FitHowie
//
//  新增訓練視圖 - 移除左上角 Edit 按鈕
//  包含 ExerciseSetData, SetData, ExerciseDetailEditor, SetConfigurationCard
//

import SwiftUI
import SwiftData
import PhotosUI
import AVKit

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 狀態變數
    @State private var date = Date()
    @State private var selectedType: TrainingType = .anaerobic
    @State private var durationMinutes = ""
    @State private var note = ""
    @State private var exercises: [ExerciseSetData] = []
    
    var body: some View {
        NavigationStack {
            Form {
                // 日期選擇區塊
                Section("日期與時間") {
                    DatePicker("開始時間", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                // 訓練類型
                Section {
                    Picker("訓練類型", selection: $selectedType) {
                        ForEach(TrainingType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // 訓練時長
                Section("訓練資訊") {
                    HStack {
                        TextField("訓練時長", text: $durationMinutes)
                            .keyboardType(.numberPad)
                        Text("分鐘")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // 動作列表 (僅無氧訓練顯示)
                if selectedType == .anaerobic {
                    Section {
                        // 使用 $exercises 綁定，支援直接編輯
                        ForEach($exercises) { $exerciseData in
                            NavigationLink {
                                // 進入單一動作編輯
                                ExerciseDetailEditor(exercise: $exerciseData)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(exerciseData.exerciseName.isEmpty ? "未命名動作" : exerciseData.exerciseName)
                                            .font(.headline)
                                        Spacer()
                                        // 如果有媒體，顯示一個小圖示
                                        if exerciseData.mediaData != nil || exerciseData.existingFilename != nil {
                                            Image(systemName: (exerciseData.mediaType ?? "photo") == "video" ? "video.fill" : "photo.fill")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    
                                    HStack {
                                        Text("\(exerciseData.muscleGroup.rawValue) • \(exerciseData.exerciseType.rawValue)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        if !exerciseData.sets.isEmpty {
                                            let totalSets = exerciseData.sets.reduce(0) { $0 + $1.numberOfSets }
                                            Text("\(totalSets) 組")
                                                .font(.caption)
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    if let note = exerciseData.note, !note.isEmpty {
                                        Text(note)
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            exercises.remove(atOffsets: indexSet)
                        }
                        .onMove { from, to in
                            exercises.move(fromOffsets: from, toOffset: to)
                        }
                        
                        Button {
                            exercises.append(ExerciseSetData())
                        } label: {
                            Label("新增動作", systemImage: "plus.circle.fill")
                        }
                    } header: {
                        HStack {
                            Text("動作列表")
                            Spacer()
                            // 移除按鈕後，提示使用者長按
                            if !exercises.isEmpty {
                                Text("長按動作可拖曳排序")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // 備註
                Section("備註") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("新增訓練")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                // MARK: - 已移除 EditButton (左上角只剩取消)
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        saveWorkout()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    // MARK: - 邏輯處理
    
    private var canSave: Bool {
        guard let duration = Int(durationMinutes), duration > 0 else { return false }
        if selectedType == .anaerobic {
            return !exercises.isEmpty && exercises.allSatisfy { !$0.exerciseName.isEmpty && !$0.sets.isEmpty }
        }
        return true
    }
    
    private func saveWorkout() {
        guard let duration = Int(durationMinutes) else { return }
        
        // 建立主紀錄
        let workout = WorkoutRecord(
            timestamp: date,
            trainingType: selectedType,
            durationMinutes: duration,
            note: note.isEmpty ? nil : note
        )
        
        if selectedType == .anaerobic {
            // MARK: - 儲存時寫入順序 (index)
            for (index, exerciseData) in exercises.enumerated() {
                // 1. 轉換組數
                var allSets: [SetEntry] = []
                for setData in exerciseData.sets {
                    let weightInKg = exerciseData.weightUnit.toKg(setData.weight)
                    for _ in 0..<setData.numberOfSets {
                        allSets.append(SetEntry(weight: weightInKg, reps: setData.reps))
                    }
                }
                
                // 2. 處理每個動作的媒體檔案
                var filename: String?
                if let data = exerciseData.mediaData, let type = exerciseData.mediaType {
                    let ext = (type == "video") ? "mov" : "jpg"
                    filename = MediaHelper.saveMedia(data: data, extensionName: ext)
                }
                
                // 3. 建立 ExerciseSet (含 orderIndex)
                let exercise = ExerciseSet(
                    exerciseName: exerciseData.exerciseName,
                    exerciseType: exerciseData.exerciseType,
                    muscleGroup: exerciseData.muscleGroup,
                    sets: allSets,
                    note: exerciseData.note?.isEmpty == false ? exerciseData.note : nil,
                    mediaFilename: filename,
                    mediaType: exerciseData.mediaType,
                    orderIndex: index // 寫入順序
                )
                workout.exerciseDetails.append(exercise)
            }
        }
        
        modelContext.insert(workout)
        dismiss()
    }
}

// MARK: - 共用資料結構

struct ExerciseSetData: Identifiable {
    let id = UUID()
    
    var exerciseName: String = ""
    var exerciseType: ExerciseType = .freeWeight
    var muscleGroup: MuscleGroup = .chest
    var weightUnit: WeightUnit = .kg
    var sets: [SetData] = []
    var note: String? = nil
    
    // 媒體暫存
    var mediaData: Data? = nil
    var mediaType: String? = nil
    var existingFilename: String? = nil
}

struct SetData: Identifiable {
    let id = UUID()
    var weight: Double = 20
    var reps: Int = 10
    var numberOfSets: Int = 3
}

// MARK: - 動作詳細編輯器 (Sub-View)

struct ExerciseDetailEditor: View {
    @Binding var exercise: ExerciseSetData
    @State private var isCustomExercise = false
    
    // 媒體選擇器狀態
    @State private var selectedItem: PhotosPickerItem?
    
    private var exerciseOptions: [String] {
        ExerciseLibrary.exercises(for: exercise.muscleGroup, exerciseType: exercise.exerciseType)
    }
    
    var body: some View {
        Form {
            Section("動作資訊") {
                Picker("訓練類型", selection: $exercise.exerciseType) {
                    ForEach(ExerciseType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .onChange(of: exercise.exerciseType) { _, _ in
                    exercise.exerciseName = ""
                    isCustomExercise = false
                }
                
                Picker("目標部位", selection: $exercise.muscleGroup) {
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        Text(group.rawValue).tag(group)
                    }
                }
                .onChange(of: exercise.muscleGroup) { _, _ in
                    exercise.exerciseName = ""
                    isCustomExercise = false
                }
                
                // 動作名稱選擇邏輯
                if isCustomExercise {
                    HStack {
                        TextField("動作名稱", text: $exercise.exerciseName)
                        Button("選擇") {
                            isCustomExercise = false
                            exercise.exerciseName = ""
                        }
                        .foregroundStyle(.blue)
                    }
                } else {
                    Picker("動作名稱", selection: $exercise.exerciseName) {
                        Text("請選擇").tag("")
                        ForEach(exerciseOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                        Text("其他/自訂").tag("其他")
                    }
                    .onChange(of: exercise.exerciseName) { _, newValue in
                        if newValue == "其他" {
                            isCustomExercise = true
                            exercise.exerciseName = ""
                        }
                    }
                }
                
                Picker("重量單位", selection: $exercise.weightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // 動作影像紀錄
            Section("動作影像 (PR/姿勢檢查)") {
                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                    // 1. 優先顯示新選擇的資料
                    if let data = exercise.mediaData, let type = exercise.mediaType {
                        if type == "photo", let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(8)
                        } else {
                            ZStack {
                                Color.black.frame(height: 200).cornerRadius(8)
                                Image(systemName: "play.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                                Text("新影片已選取")
                                    .foregroundStyle(.white)
                                    .padding(.top, 40)
                            }
                        }
                    }
                    // 2. 顯示舊檔案 (編輯模式用)
                    else if let filename = exercise.existingFilename, let url = getURL(filename: filename) {
                        if exercise.mediaType == "video" {
                             ZStack {
                                 Color.black.frame(height: 200).cornerRadius(8)
                                 Image(systemName: "play.circle.fill")
                                     .font(.largeTitle)
                                     .foregroundStyle(.white)
                                 Text("已儲存的影片")
                                     .foregroundStyle(.white)
                                     .padding(.top, 40)
                             }
                        } else {
                            AsyncImage(url: url) { img in
                                img.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 200)
                            .cornerRadius(8)
                        }
                    }
                    // 3. 無資料
                    else {
                        Label("上傳照片或影片", systemImage: "camera")
                    }
                }
                .onChange(of: selectedItem) { _, newItem in
                    loadMedia(from: newItem)
                }
                
                if exercise.mediaData != nil || exercise.existingFilename != nil {
                    Button("移除影像", role: .destructive) {
                        selectedItem = nil
                        exercise.mediaData = nil
                        exercise.existingFilename = nil
                        exercise.mediaType = nil
                    }
                }
            }
            
            Section {
                ForEach($exercise.sets) { $set in
                    SetConfigurationCard(set: $set, weightUnit: exercise.weightUnit)
                }
                .onDelete { indexSet in
                    exercise.sets.remove(atOffsets: indexSet)
                }
                
                Button {
                    exercise.sets.append(SetData())
                } label: {
                    Label("新增訓練配置", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("訓練配置")
            } footer: {
                if !exercise.sets.isEmpty {
                    let totalVolume = exercise.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps) * Double($1.numberOfSets)) }
                    let volumeInKg = exercise.weightUnit.toKg(totalVolume)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("總訓練量: \(String(format: "%.1f", totalVolume)) \(exercise.weightUnit.shortName)")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        if exercise.weightUnit == .lb {
                            Text("(約 \(String(format: "%.1f", volumeInKg)) kg)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                 }
            }
            
            Section("備註") {
                TextEditor(text: Binding(
                    get: { exercise.note ?? "" },
                    set: { exercise.note = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 80)
            }
        }
        .navigationTitle("編輯動作")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 讀取媒體邏輯
    private func loadMedia(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let movie = try? await item.loadTransferable(type: Data.self),
               item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                await MainActor.run {
                    exercise.mediaData = movie
                    exercise.mediaType = "video"
                }
                return
            }
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    exercise.mediaData = data
                    exercise.mediaType = "photo"
                }
            }
        }
    }
    
    private func getURL(filename: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename)
    }
}

// MARK: - 單組配置卡片

struct SetConfigurationCard: View {
    @Binding var set: SetData
    let weightUnit: WeightUnit
    
    private var weightStep: Double {
        weightUnit == .kg ? 2.5 : 5.0
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // 重量
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("重量")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", set.weight))
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text(weightUnit.shortName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $set.weight, in: 0...200, step: weightStep)
                    .tint(.blue)
            }
            Divider()
            
            // 次數
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("次數")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(set.reps)")
                        .font(.headline)
                        .foregroundStyle(.green)
                    Text("下")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(set.reps) },
                    set: { set.reps = Int($0) }
                ), in: 1...50, step: 1.0)
                .tint(.green)
            }
            Divider()
            
            // 組數
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("組數")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(set.numberOfSets)")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    Text("組")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(set.numberOfSets) },
                    set: { set.numberOfSets = Int($0) }
                ), in: 1...10, step: 1.0)
                .tint(.orange)
            }
            
            // 訓練量統計
            VStack(spacing: 4) {
                Divider()
                HStack {
                    Text("單組訓練量:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    let singleSetVolume = set.weight * Double(set.reps)
                    Text("\(String(format: "%.1f", singleSetVolume)) \(weightUnit.shortName)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                HStack {
                    Text("總訓練量 (\(set.numberOfSets) 組):")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    let totalVolume = set.weight * Double(set.reps) * Double(set.numberOfSets)
                    Text("\(String(format: "%.1f", totalVolume)) \(weightUnit.shortName)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
