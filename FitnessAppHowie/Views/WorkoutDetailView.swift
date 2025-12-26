//
//  WorkoutDetailView.swift
//  FitHowie
//
//  訓練詳情視圖 - 支援多媒體輪播
//

import SwiftUI
import SwiftData
import AVKit

struct WorkoutDetailView: View {
    let workout: WorkoutRecord
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            // 1. 訓練基本資訊
            Section("訓練資訊") {
                HStack {
                     Text("訓練類型")
                     Spacer()
                     Text(workout.trainingType.rawValue)
                         .foregroundStyle(.secondary)
                 }
                 
                 HStack {
                     Text("訓練時長")
                     Spacer()
                     Text("\(workout.durationMinutes) 分鐘")
                         .foregroundStyle(.secondary)
                 }
                 
                 HStack {
                     Text("記錄時間")
                     Spacer()
                     Text(workout.timestamp, style: .date)
                         .foregroundStyle(.secondary)
                 }
                 
                 HStack {
                     Text("開始時間")
                     Spacer()
                     Text(workout.timestamp, style: .time)
                         .foregroundStyle(.secondary)
                 }
            }
            
            // 2. 動作詳情 (含多媒體)
            if workout.trainingType == .anaerobic && !workout.exerciseDetails.isEmpty {
                 Section("動作詳情") {
                     ForEach(workout.sortedExercises, id: \.id) { exercise in
                         VStack(alignment: .leading, spacing: 10) {
                             
                             // A. 動作名稱
                             Text(exercise.exerciseName)
                                 .font(.headline)
                             
                             // MARK: - B. 多媒體輪播顯示
                             if !exercise.mediaItems.isEmpty {
                                 if exercise.mediaItems.count == 1 {
                                     // 單個媒體：直接顯示
                                     SingleMediaView(mediaItem: exercise.mediaItems[0])
                                         .frame(height: 250)
                                         .cornerRadius(12)
                                         .padding(.vertical, 4)
                                 } else {
                                     // 多個媒體：使用 TabView 輪播
                                     MultipleMediaView(mediaItems: exercise.mediaItems)
                                         .frame(height: 280)
                                         .padding(.vertical, 4)
                                 }
                             }
                             
                             // C. 部位與類型標籤
                             HStack {
                                 Label(exercise.muscleGroup.rawValue, systemImage: "figure.strengthtraining.traditional")
                                     .font(.caption)
                                     .foregroundStyle(.secondary)
                                 Label(exercise.exerciseType.rawValue, systemImage: "list.bullet")
                                     .font(.caption)
                                     .foregroundStyle(.secondary)
                             }
                             
                             // D. 組數列表
                             VStack(alignment: .leading, spacing: 5) {
                                 ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                                     HStack {
                                         Text("第 \(index + 1) 組")
                                             .font(.caption)
                                             .frame(width: 60, alignment: .leading)
                                         Text(String(format: "%.1f kg × %d 下", set.weight, set.reps))
                                             .font(.caption)
                                     }
                                 }
                             }
                             .padding(.leading)
                             
                             // E. 統計數據
                             HStack {
                                 Text("訓練量: \(String(format: "%.0f", exercise.totalVolume)) kg")
                                     .font(.caption2)
                                     .foregroundStyle(.blue)
                                 Spacer()
                                 Text("最大重量: \(String(format: "%.1f", exercise.maxWeight)) kg")
                                     .font(.caption2)
                                     .foregroundStyle(.orange)
                             }
                             .padding(.top, 5)
                             
                             // F. 備註
                             if let note = exercise.note, !note.isEmpty {
                                 Divider()
                                 VStack(alignment: .leading, spacing: 4) {
                                     Label("動作備註", systemImage: "note.text")
                                         .font(.caption)
                                         .foregroundStyle(.secondary)
                                     Text(note)
                                         .font(.caption)
                                         .foregroundStyle(.primary)
                                         .padding(8)
                                         .frame(maxWidth: .infinity, alignment: .leading)
                                         .background(Color(.systemGray6))
                                         .cornerRadius(8)
                                 }
                             }
                         }
                         .padding(.vertical, 8)
                     }
                 }
                 
                 // 3. 整場訓練統計
                 Section("訓練統計") {
                     HStack {
                         Text("總動作數")
                         Spacer()
                         Text("\(workout.exerciseDetails.count) 個")
                             .foregroundStyle(.secondary)
                     }
                     
                     HStack {
                         Text("總組數")
                         Spacer()
                         Text("\(workout.exerciseDetails.reduce(0) { $0 + $1.sets.count }) 組")
                             .foregroundStyle(.secondary)
                     }
                     
                     HStack {
                         Text("總訓練量")
                         Spacer()
                         Text(String(format: "%.0f kg", workout.totalVolume))
                             .foregroundStyle(.blue)
                             .fontWeight(.semibold)
                     }
                 }
             }
            
            if let note = workout.note, !note.isEmpty {
                Section("整場備註") {
                    Text(note)
                }
            }
        }
        .navigationTitle("訓練詳情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("編輯") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditWorkoutView(workout: workout)
        }
    }
}

// MARK: - 單個媒體顯示組件

struct SingleMediaView: View {
    let mediaItem: ExerciseSet.MediaItem
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        Group {
            if mediaItem.type == "video", let url = mediaItem.url {
                ZStack(alignment: .center) {
                    VideoPlayer(player: player)
                    
                    Button {
                        togglePlayPause()
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(radius: 4)
                    }
                    .opacity(isPlaying ? 0.0 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isPlaying)
                }
                .task {
                    if player == nil {
                        player = AVPlayer(url: url)
                    }
                }
                .onDisappear {
                    player?.pause()
                    isPlaying = false
                }
            } else if let url = mediaItem.url {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFit()
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                    }
                }
            }
        }
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            if let currentItem = player.currentItem, currentItem.currentTime() >= currentItem.duration {
                player.seek(to: .zero)
            }
            player.play()
            isPlaying = true
        }
    }
}

// MARK: - 多媒體輪播組件

struct MultipleMediaView: View {
    let mediaItems: [ExerciseSet.MediaItem]
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentIndex) {
                ForEach(Array(mediaItems.enumerated()), id: \.element.id) { index, item in
                    SingleMediaView(mediaItem: item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .cornerRadius(12)
            
            // 媒體計數器與類型標示
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: mediaItems[currentIndex].type == "video" ? "video.fill" : "photo.fill")
                        .font(.caption2)
                    Text("\(currentIndex + 1) / \(mediaItems.count)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemBackground).opacity(0.8))
                .clipShape(Capsule())
                Spacer()
            }
            .offset(y: -20)
        }
    }
}
