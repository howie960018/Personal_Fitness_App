//
//  ContentView.swift
//  FitHowie
//
//  主要介面 - TabView 結構
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("儀錶板", systemImage: "chart.bar.fill")
                }
            
            WorkoutLoggerView()
                .tabItem {
                    Label("訓練", systemImage: "dumbbell.fill")
                }
            
            NutritionJournalView()
                .tabItem {
                    Label("飲食", systemImage: "fork.knife")
                }
            
            AnalyticsView()
                .tabItem {
                    Label("分析", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            DailyLog.self,
            WorkoutRecord.self,
            ExerciseSet.self,
            SetEntry.self,
            NutritionEntry.self
        ], inMemory: true)
}
