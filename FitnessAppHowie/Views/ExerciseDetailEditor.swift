//
//  ExerciseDetailEditor.swift
//  FitHowie
//
//  動作詳細編輯器 - 修正科學記號顯示問題 (2e+01 -> 20.0)
//

import SwiftUI
import PhotosUI
import AVKit

// MARK: - 資料結構定義

struct ExerciseSetData: Identifiable {
    let id = UUID()
    
    var exerciseName: String = ""
    var exerciseType: ExerciseType = .freeWeight
    var muscleGroup: MuscleGroup = .chest
    var weightUnit: WeightUnit = .kg
    var sets: [SetData] = []
    var note: String? = nil
    
    // 支援多個媒體
    struct MediaData: Identifiable {
        let id = UUID()
        let data: Data
        let type: String  // "photo" or "video"
    }
    
    var mediaDataArray: [MediaData] = []          // 新選擇的多個媒體
    var existingFilenames: [String] = []          // 既有的檔名陣列
    var existingTypes: [String] = []              // 既有的類型陣列
    
    // 向下相容屬性
    var hasAnyMedia: Bool {
        !mediaDataArray.isEmpty || !existingFilenames.isEmpty
    }
    
    var totalMediaCount: Int {
        mediaDataArray.count + existingFilenames.count
    }
}

struct SetData: Identifiable {
    let id = UUID()
    var weight: Double = 20
    var reps: Int = 10
    var numberOfSets: Int = 3
}

// MARK: - 主要編輯器視圖

struct ExerciseDetailEditor: View {
    @Binding var exercise: ExerciseSetData
    @State private var isCustomExercise = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoadingMedia = false
    
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
            
            Section("動作影像 (可選多個)") {
                // 既有媒體管理
                if !exercise.existingFilenames.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("目前媒體 (\(exercise.existingFilenames.count) 個)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(exercise.existingFilenames.enumerated()), id: \.offset) { index, filename in
                                    ExistingMediaThumbnail(
                                        filename: filename,
                                        type: index < exercise.existingTypes.count ? exercise.existingTypes[index] : "photo",
                                        onDelete: {
                                            exercise.existingFilenames.remove(at: index)
                                            if index < exercise.existingTypes.count {
                                                exercise.existingTypes.remove(at: index)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .any(of: [.images, .videos])) {
                    Label(
                        exercise.mediaDataArray.isEmpty ? "新增照片/影片 (最多10個)" : "已選擇 \(exercise.mediaDataArray.count) 個新媒體",
                        systemImage: exercise.mediaDataArray.isEmpty ? "photo.badge.plus" : "checkmark.circle.fill"
                    )
                    .foregroundStyle(exercise.mediaDataArray.isEmpty ? .blue : .green)
                }
                .onChange(of: selectedItems) { _, newItems in loadMedia(from: newItems) }
                
                if isLoadingMedia {
                    HStack { ProgressView(); Text("載入中...").font(.caption).foregroundStyle(.secondary) }
                }
            }
            
            Section("訓練配置") {
                ForEach($exercise.sets) { $set in
                    SetConfigurationCard(set: $set, weightUnit: exercise.weightUnit)
                }
                .onDelete { exercise.sets.remove(atOffsets: $0) }
                
                Button { exercise.sets.append(SetData()) } label: {
                    Label("新增訓練配置", systemImage: "plus.circle.fill")
                }
            }
            
            Section("備註") {
                TextEditor(text: Binding(get: { exercise.note ?? "" }, set: { exercise.note = $0.isEmpty ? nil : $0 }))
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle("編輯動作")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func loadMedia(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isLoadingMedia = true
        exercise.mediaDataArray.removeAll()
        Task {
            for item in items {
                if let movie = try? await item.loadTransferable(type: Data.self),
                   item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                    await MainActor.run { exercise.mediaDataArray.append(.init(data: movie, type: "video")) }
                } else if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run { exercise.mediaDataArray.append(.init(data: data, type: "photo")) }
                }
            }
            await MainActor.run { isLoadingMedia = false }
        }
    }
}

// MARK: - SetConfigurationCard (修正顯示格式)

struct SetConfigurationCard: View {
    @Binding var set: SetData
    let weightUnit: WeightUnit
    
    @State private var weightInput: String = ""
    @FocusState private var isWeightFieldFocused: Bool
    
    private let repsOptions = Array(1...50)
    private let setsOptions = Array(1...10)
    
    var body: some View {
        VStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("重量")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(weightUnit.shortName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // MARK: - 修改 1: 確保鍵盤輸入格式正確
                TextField("0.0", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isWeightFieldFocused ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .focused($isWeightFieldFocused)
                    .onChange(of: weightInput) { _, newValue in
                        // 過濾非數字字元並限制長度
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if let value = Double(filtered), value >= 0 {
                            set.weight = value
                        }
                    }
                    .onAppear {
                        // MARK: - 修改 2: 初始化顯示，移除科學記號
                        // 使用簡潔的格式化：如果是 20.0 就顯示 20，如果是 22.5 就顯示 22.5
                        weightInput = set.weight.truncatingRemainder(dividingBy: 1) == 0 ?
                            String(format: "%.0f", set.weight) :
                            String(format: "%.1f", set.weight)
                    }
            }
            
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("次數")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("次數", selection: $set.reps) {
                        ForEach(repsOptions, id: \.self) { Text("\($0) 下").tag($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("組數")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("組數", selection: $set.numberOfSets) {
                        ForEach(setsOptions, id: \.self) { Text("\($0) 組").tag($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
            
            HStack {
                let totalVolume = set.weight * Double(set.reps) * Double(set.numberOfSets)
                Text("總訓練量:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                // 這裡也同步使用修正後的格式化
                Text("\(String(format: "%.1f", totalVolume)) \(weightUnit.shortName)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                Spacer()
            }
            .padding(.top, 5)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 輔助縮圖組件 (保持不變)
struct ExistingMediaThumbnail: View {
    let filename: String; let type: String; let onDelete: () -> Void
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename) {
                if type == "video" {
                    ZStack {
                        Color.black.frame(width: 100, height: 100).cornerRadius(10)
                        Image(systemName: "play.circle.fill").font(.title).foregroundStyle(.white)
                    }
                } else {
                    AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { ProgressView() }
                        .frame(width: 100, height: 100).clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            Button(action: onDelete) { Image(systemName: "xmark.circle.fill").foregroundStyle(.white).background(Circle().fill(.red)) }.padding(4)
        }
    }
}

struct NewMediaThumbnail: View {
    let mediaData: ExerciseSetData.MediaData; let onDelete: () -> Void
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if mediaData.type == "video" {
                ZStack {
                    Color.black.frame(width: 100, height: 100).cornerRadius(10)
                    Image(systemName: "play.circle.fill").font(.title).foregroundStyle(.white)
                }
            } else if let uiImage = UIImage(data: mediaData.data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
                    .frame(width: 100, height: 100).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Button(action: onDelete) { Image(systemName: "xmark.circle.fill").foregroundStyle(.white).background(Circle().fill(.red)) }.padding(4)
        }
    }
}
