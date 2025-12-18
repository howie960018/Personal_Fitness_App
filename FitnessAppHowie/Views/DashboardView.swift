//
//  DashboardView.swift
//  FitHowie
//
//  儀錶板視圖 - 總覽今日狀況、快速導航與歷史紀錄
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - 修改 1: 加入排序，讓日期新的在上面
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    
    @State private var showingDailyLogSheet = false
    @State private var showingWorkoutSheet = false
    @State private var showingNutritionSheet = false
    
    // MARK: - 修改 2: 用來控制編輯歷史紀錄的狀態
    @State private var selectedLogToEdit: DailyLog?
    
    // 取得今天的紀錄
    var todayLog: DailyLog? {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    // MARK: - 修改 3: 取得歷史紀錄 (排除今天，取前 7 筆顯示)
    var historyLogs: [DailyLog] {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyLogs
            .filter { !Calendar.current.isDate($0.date, inSameDayAs: today) }
            // .prefix(7) // 如果只想顯示最近7天，可以打開這行
            // .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 今日數據卡片
                    todayDataCard
                    
                    // 快速操作按鈕
                    quickActionsSection
                    
                    // MARK: - 修改 4: 加入歷史紀錄區塊
                    if !historyLogs.isEmpty {
                        historySection
                    }
                }
                .padding()
            }
            .navigationTitle("儀錶板")
            
            // 處理「新增/編輯今日」的 Sheet
            .sheet(isPresented: $showingDailyLogSheet) {
                DailyLogFormView(existingLog: todayLog)
            }
            
            // 處理「新增訓練」的 Sheet
            .sheet(isPresented: $showingWorkoutSheet) {
                AddWorkoutView()
            }
            
            // 處理「新增飲食」的 Sheet
            .sheet(isPresented: $showingNutritionSheet) {
                AddNutritionEntryView()
            }
            
            // MARK: - 修改 5: 處理「編輯歷史紀錄」的 Sheet
            // 當 selectedLogToEdit 被賦值時，會彈出這個視窗
            .sheet(item: $selectedLogToEdit) { log in
                DailyLogFormView(existingLog: log)
            }
        }
    }
    
    // ... (todayDataCard 保持不變) ...
    private var todayDataCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("今日數據")
                    .font(.headline)
                Spacer()
                Text(Date(), style: .date) // 顯示今日日期
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let log = todayLog {
                VStack(spacing: 10) {
                    if let weight = log.weight {
                        DataRow(icon: "scalemass", label: "體重", value: String(format: "%.1f kg", weight))
                    }
                    if let steps = log.steps {
                        DataRow(icon: "figure.walk", label: "步數", value: "\(steps) 步")
                    }
                    if let heartRate = log.restingHeartRate {
                        DataRow(icon: "heart.fill", label: "靜止心率", value: "\(heartRate) BPM")
                    }
                    if let sleep = log.sleepDurationHours {
                        DataRow(icon: "bed.double.fill", label: "睡眠", value: String(format: "%.1f 小時", sleep))
                    }
                    // 如果都沒填寫顯示提示
                    if log.weight == nil && log.steps == nil && log.restingHeartRate == nil && log.sleepDurationHours == nil {
                         Text("點擊編輯今日數據")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            } else {
                Text("尚未記錄今日數據")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onTapGesture {
            showingDailyLogSheet = true
        }
    }
    
    // ... (quickActionsSection 保持不變) ...
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("快速操作")
                .font(.headline)
            
            VStack(spacing: 12) {
                QuickActionButton(
                    icon: "dumbbell.fill",
                    title: "新增訓練",
                    color: .blue
                ) {
                    showingWorkoutSheet = true
                }
                
                QuickActionButton(
                    icon: "fork.knife",
                    title: "新增飲食",
                    color: .green
                ) {
                    showingNutritionSheet = true
                }
                
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "新增每日數據",
                    color: .orange
                ) {
                    showingDailyLogSheet = true
                }
            }
        }
    }
    
    // MARK: - 修改 6: 歷史紀錄視圖組件
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("歷史紀錄")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(historyLogs) { log in
                    Button {
                        selectedLogToEdit = log // 點擊後觸發 sheet
                    } label: {
                        HistoryRow(log: log)
                    }
                    .buttonStyle(.plain) // 讓按鈕樣式更自然
                }
            }
        }
    }
}

// ... (DataRow 保持不變) ...
struct DataRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 30)
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// ... (QuickActionButton 保持不變) ...
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - 修改 7: 新增歷史紀錄單行組件
struct HistoryRow: View {
    let log: DailyLog
    
    // 日期格式化：顯示 "12/18 (週四)"
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd (EE)"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: log.date)
    }
    
    var body: some View {
        HStack {
            // 左側：日期
            VStack(alignment: .leading) {
                Text(dateString)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(width: 80, alignment: .leading)
            
            // 中間：重點數據摘要 (體重 > 步數 > 睡眠)
            VStack(alignment: .leading, spacing: 4) {
                if let weight = log.weight {
                    Label(String(format: "%.1f kg", weight), systemImage: "scalemass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let steps = log.steps {
                    // 如果沒記體重，顯示步數
                    Label("\(steps) 步", systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("無詳細數據")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 右側：箭頭
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [DailyLog.self], inMemory: true)
}
