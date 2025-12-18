//
//  EditWorkoutView.swift
//  FitHowie
//
//  編輯訓練視圖 - 支援拖曳排序
//

import SwiftUI
import SwiftData
import PhotosUI
import AVKit

struct EditWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workout: WorkoutRecord
    
    @State private var date: Date
    @State private var selectedType: TrainingType
    @State private var durationMinutes: String
    @State private var note: String
    @State private var exercises: [ExerciseSetData] = []
    
    @State private var hasLoadedData = false
    
    init(workout: WorkoutRecord) {
        self.workout = workout
        _date = State(initialValue: workout.timestamp)
        _selectedType = State(initialValue: workout.trainingType)
        _durationMinutes = State(initialValue: String(workout.durationMinutes))
        _note = State(initialValue: workout.note ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本資訊") {
                    DatePicker("記錄時間", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    Picker("訓練類型", selection: $selectedType) {
                        ForEach(TrainingType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("訓練資訊") {
                    HStack {
                        TextField("訓練時長", text: $durationMinutes)
                            .keyboardType(.numberPad)
                        Text("分鐘")
                            .foregroundStyle(.secondary)
                    }
                }
                
                if selectedType == .anaerobic {
                    Section {
                        // MARK: - 修改 1: 使用 $exercises 遍歷
                        ForEach($exercises) { $exerciseData in
                            NavigationLink {
                                ExerciseDetailEditor(exercise: $exerciseData)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(exerciseData.exerciseName.isEmpty ? "未命名動作" : exerciseData.exerciseName)
                                            .font(.headline)
                                        Spacer()
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
                        // MARK: - 修改 2: 加入 .onMove
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
                                Text("長按或點擊編輯排序")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Section("備註") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("編輯訓練")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                // 加入 EditButton 讓使用者能明確進入排序模式
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        saveWorkout()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if !hasLoadedData {
                    loadExistingData()
                    hasLoadedData = true
                }
            }
        }
    }
    
    private var canSave: Bool {
        guard let duration = Int(durationMinutes), duration > 0 else { return false }
        if selectedType == .anaerobic {
            return !exercises.isEmpty && exercises.allSatisfy { !$0.exerciseName.isEmpty && !$0.sets.isEmpty }
        }
        return true
    }
    
    private func loadExistingData() {
            if selectedType == .anaerobic {
                var exerciseDataArray: [ExerciseSetData] = []
                
                // MARK: - 修改：讀取時使用 sortedExercises 確保順序正確
                for exercise in workout.sortedExercises {
                    var exerciseData = ExerciseSetData(
                        exerciseName: exercise.exerciseName,
                        exerciseType: exercise.exerciseType,
                        muscleGroup: exercise.muscleGroup,
                        note: exercise.note,
                        mediaType: exercise.mediaType,
                        existingFilename: exercise.mediaFilename
                    )
                    
                    // ... (處理 sets 的邏輯不變) ...
                    
                    var setGroups: [String: (weight: Double, reps: Int, count: Int)] = [:]
                    for set in exercise.sets {
                       let key = "\(set.weight)-\(set.reps)"
                        if var existing = setGroups[key] {
                            existing.count += 1
                            setGroups[key] = existing
                        } else {
                            setGroups[key] = (weight: set.weight, reps: set.reps, count: 1)
                        }
                    }
                    exerciseData.sets = setGroups.values.map { group in
                        SetData(weight: group.weight, reps: group.reps, numberOfSets: group.count)
                    }
                    
                    exerciseDataArray.append(exerciseData)
                }
                exercises = exerciseDataArray
            }
        }
    
    private func saveWorkout() {
            guard let duration = Int(durationMinutes) else { return }
            
            workout.timestamp = date
            workout.trainingType = selectedType
            workout.durationMinutes = duration
            workout.note = note.isEmpty ? nil : note
            
            workout.exerciseDetails.removeAll()
            
            if selectedType == .anaerobic {
                // MARK: - 修改：使用 enumerated() 寫入新的順序
                for (index, exerciseData) in exercises.enumerated() {
                    var finalFilename = exerciseData.existingFilename
                    var finalType = exerciseData.mediaType
                    
                    if let data = exerciseData.mediaData, let type = exerciseData.mediaType {
                        MediaHelper.deleteMedia(filename: exerciseData.existingFilename)
                        let ext = (type == "video") ? "mov" : "jpg"
                        finalFilename = MediaHelper.saveMedia(data: data, extensionName: ext)
                        finalType = type
                    }
                    else if exerciseData.existingFilename == nil && exerciseData.mediaData == nil {
                         // 處理移除
                    }
                    
                    var allSets: [SetEntry] = []
                    for setData in exerciseData.sets {
                        let weightInKg = exerciseData.weightUnit.toKg(setData.weight)
                        for _ in 0..<setData.numberOfSets {
                            allSets.append(SetEntry(weight: weightInKg, reps: setData.reps))
                        }
                    }
                    
                    let exercise = ExerciseSet(
                        exerciseName: exerciseData.exerciseName,
                        exerciseType: exerciseData.exerciseType,
                        muscleGroup: exerciseData.muscleGroup,
                        sets: allSets,
                        note: exerciseData.note?.isEmpty == false ? exerciseData.note : nil,
                        mediaFilename: finalFilename,
                        mediaType: finalType,
                        orderIndex: index // 👈 關鍵：更新為拖曳後的新順序
                    )
                    workout.exerciseDetails.append(exercise)
                }
            }
            
            dismiss()
        }
}
