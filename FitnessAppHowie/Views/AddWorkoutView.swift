//
//  AddWorkoutView.swift
//  FitHowie
//
//  新增訓練視圖 - 支援多媒體上傳
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
                        ForEach($exercises) { $exerciseData in
                            NavigationLink {
                                ExerciseDetailEditor(exercise: $exerciseData)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(exerciseData.exerciseName.isEmpty ? "未命名動作" : exerciseData.exerciseName)
                                            .font(.headline)
                                        Spacer()
                                        // 顯示媒體數量
                                        if exerciseData.hasAnyMedia {
                                            HStack(spacing: 4) {
                                                Image(systemName: "photo.fill")
                                                    .foregroundStyle(.blue)
                                                Text("\(exerciseData.totalMediaCount)")
                                                    .font(.caption)
                                                    .foregroundStyle(.blue)
                                            }
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
        
        let workout = WorkoutRecord(
            timestamp: date,
            trainingType: selectedType,
            durationMinutes: duration,
            note: note.isEmpty ? nil : note
        )
        
        if selectedType == .anaerobic {
            for (index, exerciseData) in exercises.enumerated() {
                
                // 1. 轉換組數
                var allSets: [SetEntry] = []
                for setData in exerciseData.sets {
                    let weightInKg = exerciseData.weightUnit.toKg(setData.weight)
                    for _ in 0..<setData.numberOfSets {
                        allSets.append(SetEntry(weight: weightInKg, reps: setData.reps))
                    }
                }
                
                // MARK: - 2. 處理多個媒體檔案
                var savedFilenames: [String] = []
                var savedTypes: [String] = []
                
                for mediaData in exerciseData.mediaDataArray {
                    let ext = (mediaData.type == "video") ? "mov" : "jpg"
                    if let filename = MediaHelper.saveMedia(data: mediaData.data, extensionName: ext) {
                        savedFilenames.append(filename)
                        savedTypes.append(mediaData.type)
                    }
                }
                
                // 3. 建立 ExerciseSet (使用多媒體參數)
                let exercise = ExerciseSet(
                    exerciseName: exerciseData.exerciseName,
                    exerciseType: exerciseData.exerciseType,
                    muscleGroup: exerciseData.muscleGroup,
                    sets: allSets,
                    note: exerciseData.note?.isEmpty == false ? exerciseData.note : nil,
                    mediaFilenames: savedFilenames,  // 使用多媒體陣列
                    mediaTypes: savedTypes,          // 使用多類型陣列
                    orderIndex: index
                )
                workout.exerciseDetails.append(exercise)
            }
        }
        
        modelContext.insert(workout)
        dismiss()
    }
}
