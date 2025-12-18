//
//  WorkoutLoggerView.swift
//  FitHowie
//
//  訓練記錄視圖 - 優化日期顯示
//

import SwiftUI
import SwiftData

struct WorkoutLoggerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutRecord.timestamp, order: .reverse) private var workouts: [WorkoutRecord]
    
    @State private var showingAddWorkout = false
    @State private var workoutToEdit: WorkoutRecord?
    
    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(workouts) { workout in
                            // 點擊項目進行編輯
                            Button {
                                workoutToEdit = workout
                            } label: {
                                WorkoutRowView(workout: workout)
                            }
                            .buttonStyle(.plain) // 移除按鈕預設樣式
                        }
                        .onDelete(perform: deleteWorkouts)
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("訓練記錄")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddWorkout = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWorkout) {
                AddWorkoutView()
            }
            .sheet(item: $workoutToEdit) { workout in
                // 使用 NavigationStack 包裹以便進入編輯與詳情，並顯示 Toolbar
                NavigationStack {
                    WorkoutDetailView(workout: workout)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("尚無訓練記錄")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("新增第一筆訓練") {
                showingAddWorkout = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(workouts[index])
            }
        }
    }
}

// MARK: - 列表單行組件 (日期顯示優化)
struct WorkoutRowView: View {
    let workout: WorkoutRecord
    
    // 定義日期格式：2025 12/8 星期一
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy M/d EEEE" // EEEE 代表完整的星期幾
        formatter.locale = Locale(identifier: "zh_TW") // 強制繁體中文
        return formatter.string(from: workout.timestamp)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 第一行：日期 + 類型標籤
            HStack {
                // MARK: - 修改：使用自訂格式的日期
                Text(dateString)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // 類型標籤 (有氧/無氧)
                Text(workout.trainingType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(workout.trainingType == .aerobic ? .green : .blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        (workout.trainingType == .aerobic ? Color.green : Color.blue).opacity(0.1)
                    )
                    .clipShape(Capsule())
            }
            
            // 第二行：純文字數據 (分鐘 • 動作 • 組數)
            HStack(spacing: 4) {
                Text("\(workout.durationMinutes) 分鐘")
                
                if workout.trainingType == .anaerobic {
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("\(workout.exerciseDetails.count) 個動作")
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    let totalSets = workout.exerciseDetails.reduce(0) { $0 + $1.sets.count }
                    Text("\(totalSets) 組")
                }
                
                Spacer()
                
                if workout.trainingType == .anaerobic && workout.totalVolume > 0 {
                    Text(String(format: "%.0f kg", workout.totalVolume))
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .bold()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
