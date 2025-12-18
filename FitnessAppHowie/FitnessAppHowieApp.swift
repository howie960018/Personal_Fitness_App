import SwiftUI
import SwiftData
import AVFoundation // 引入這個

@main
struct FitnessAppHowieApp: App {
    
    // 加入這個 init
    init() {
        do {
            // 允許在靜音模式下播放聲音
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("無法設定 Audio Session: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            DailyLog.self,
            WorkoutRecord.self,
            ExerciseSet.self,
            SetEntry.self,
            NutritionEntry.self
        ])
    }
}
