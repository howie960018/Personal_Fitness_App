//
//  AnalyticsView.swift
//  FitHowie
//
//  支援左右滑動切換日期範圍
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \DailyLog.date, order: .forward) private var allDailyLogs: [DailyLog]
    @Query(sort: \WorkoutRecord.timestamp, order: .reverse) private var allWorkouts: [WorkoutRecord]
    @Query(sort: \NutritionEntry.timestamp, order: .reverse) private var allNutritionEntries: [NutritionEntry]
    
    @State private var selectedTimePeriod: TimePeriod = .week
    @State private var selectedMetric: MuscleMetric = .sets
    @State private var selectedChartTab = 0
    
    // 新增：日期偏移量（0=本週/本月，-1=上週/上月，1=下週/下月）
    @State private var dateOffset: Int = 0
    
    // 計算當前日期範圍
    private var currentDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimePeriod {
        case .day:
            let targetDate = calendar.date(byAdding: .day, value: dateOffset, to: now)!
            let start = calendar.startOfDay(for: targetDate)
            let end = start.addingTimeInterval(24*60*60-1)
            return (start, end)
            
        case .week:
            let targetWeek = calendar.date(byAdding: .weekOfYear, value: dateOffset, to: now)!
            let end = calendar.startOfDay(for: targetWeek).addingTimeInterval(24*60*60-1)
            let start = calendar.date(byAdding: .day, value: -6, to: end)!
            return (start, end)
            
        case .month:
            let targetMonth = calendar.date(byAdding: .month, value: dateOffset, to: now)!
            let end = calendar.startOfDay(for: targetMonth).addingTimeInterval(24*60*60-1)
            let start = calendar.date(byAdding: .day, value: -29, to: end)!
            return (start, end)
        }
    }
    
    // 日期範圍顯示文字
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        
        switch selectedTimePeriod {
        case .day:
            formatter.dateFormat = "M月d日 (E)"
            return formatter.string(from: currentDateRange.start)
            
        case .week:
            formatter.dateFormat = "M/d"
            let start = formatter.string(from: currentDateRange.start)
            let end = formatter.string(from: currentDateRange.end)
            return "\(start) - \(end)"
            
        case .month:
            formatter.dateFormat = "M/d"
            let start = formatter.string(from: currentDateRange.start)
            let end = formatter.string(from: currentDateRange.end)
            return "\(start) - \(end)"
        }
    }
    
    // 相對時間文字（今天/本週/上週等）
    private var relativeTimeText: String {
        switch selectedTimePeriod {
        case .day:
            if dateOffset == 0 { return "今天" }
            else if dateOffset == -1 { return "昨天" }
            else if dateOffset == 1 { return "明天" }
            else if dateOffset < 0 { return "\(abs(dateOffset)) 天前" }
            else { return "\(dateOffset) 天後" }
            
        case .week:
            if dateOffset == 0 { return "本週" }
            else if dateOffset == -1 { return "上週" }
            else if dateOffset == 1 { return "下週" }
            else if dateOffset < 0 { return "\(abs(dateOffset)) 週前" }
            else { return "\(dateOffset) 週後" }
            
        case .month:
            if dateOffset == 0 { return "本月" }
            else if dateOffset == -1 { return "上月" }
            else if dateOffset == 1 { return "下月" }
            else if dateOffset < 0 { return "\(abs(dateOffset)) 月前" }
            else { return "\(dateOffset) 月後" }
        }
    }
    
    // 根據當前日期範圍篩選的健康數據
    private var filteredLogs: [DailyLog] {
        let range = currentDateRange
        let calendar = Calendar.current
        
        return allDailyLogs.filter { log in
            let logDate = calendar.startOfDay(for: log.date)
            return logDate >= range.start && logDate <= range.end
        }
    }
    
    // 根據日期範圍篩選的訓練記錄
    private var workouts: [WorkoutRecord] {
        let range = currentDateRange
        return allWorkouts.filter { $0.timestamp >= range.start && $0.timestamp <= range.end }
    }
    
    // 根據日期範圍篩選的飲食記錄
    private var nutritionEntries: [NutritionEntry] {
        let range = currentDateRange
        return allNutritionEntries.filter { $0.timestamp >= range.start && $0.timestamp <= range.end }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 時間週期選擇器（移到最上面）
                    timePeriodPicker
                    
                    // 日期範圍滑動卡片
                    dateRangeCard
                    
                    // 健康數據輪播（根據日期範圍顯示）
                    if !filteredLogs.isEmpty {
                        HealthMetricsCarousel(logs: filteredLogs, selectedTab: $selectedChartTab, timePeriod: selectedTimePeriod)
                            .padding(.horizontal)
                    } else {
                        emptyHealthDataView
                    }
                    
                    Divider().padding(.vertical, 5)
                    
                    // 飲食分析
                    if hasNutritionData {
                        NutritionAnalyticsSection(entries: nutritionEntries, timePeriod: selectedTimePeriod)
                    }
                    
                    // 訓練數據分析
                    if hasWorkoutData {
                        muscleBalanceSection
                        volumeTrendSection
                        workoutSummarySection
                    }
                    
                    // 空狀態
                    if !hasWorkoutData && !hasNutritionData {
                        emptyStateView
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("數據分析")
        }
    }
    
    // MARK: - 日期範圍滑動卡片
    private var dateRangeCard: some View {
        let range = dateRangeForSelection
        
        return TabView(selection: $dateOffset) {
            ForEach(range, id: \.self) { offset in
                dateRangeCardContent(for: offset)
                    .tag(offset)
            }
        }
        .frame(height: 220)  // 增加高度從 160 → 180
        .tabViewStyle(.page(indexDisplayMode: .never))
        .padding(.horizontal)
        .onChange(of: selectedTimePeriod) { oldValue, newValue in
            // 切換週期時重置為當前
            dateOffset = 0
        }
    }
    
    // 根據選擇的時間單位決定可滑動範圍
    private var dateRangeForSelection: ClosedRange<Int> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 找出所有記錄中最早的日期
        var earliestDate = today
        
        // 檢查 DailyLog
        if let firstLog = allDailyLogs.first {
            let logDate = calendar.startOfDay(for: firstLog.date)
            if logDate < earliestDate {
                earliestDate = logDate
            }
        }
        
        // 檢查 WorkoutRecord（Query 是 reverse，所以 last 才是最早）
        if let firstWorkout = allWorkouts.last {
            let workoutDate = calendar.startOfDay(for: firstWorkout.timestamp)
            if workoutDate < earliestDate {
                earliestDate = workoutDate
            }
        }
        
        // 檢查 NutritionEntry（Query 是 reverse，所以 last 才是最早）
        if let firstNutrition = allNutritionEntries.last {
            let nutritionDate = calendar.startOfDay(for: firstNutrition.timestamp)
            if nutritionDate < earliestDate {
                earliestDate = nutritionDate
            }
        }
        
        switch selectedTimePeriod {
        case .day:
            // 計算從最早記錄到今天的天數
            let daysSinceFirst = calendar.dateComponents([.day], from: earliestDate, to: today).day ?? 0
            // 可以往前滑到第一筆記錄，往後滑3天
            return (-daysSinceFirst)...3
            
        case .week:
            // 計算從最早記錄到本週的週數
            let weeksSinceFirst = calendar.dateComponents([.weekOfYear], from: earliestDate, to: today).weekOfYear ?? 0
            // 可以往前滑到第一週，往後滑4週
            return (-weeksSinceFirst)...4
            
        case .month:
            // 計算從最早記錄到本月的月數
            let monthsSinceFirst = calendar.dateComponents([.month], from: earliestDate, to: today).month ?? 0
            // 可以往前滑到第一個月，往後滑3個月
            return (-monthsSinceFirst)...3
        }
    }
    
    private func dateRangeCardContent(for offset: Int) -> some View {
        let range = calculateDateRange(for: offset)
        let workoutsCount = calculateWorkoutsCount(for: range)
        let stepsCount = calculateStepsCount(for: range)
        let caloriesCount = calculateCaloriesCount(for: range)
        
        return VStack(spacing: 14) {  // 增加間距 12 → 14
            // 標題
            VStack(spacing: 6) {
                Text(getRelativeTimeText(for: offset))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(getDateRangeText(for: range))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // 摘要數據
            HStack(spacing: 20) {
                SummaryItem(icon: "figure.run", value: "\(workoutsCount)", label: "訓練", color: .blue)
                SummaryItem(icon: "figure.walk", value: "\(stepsCount)", label: "步數", color: .green)
                SummaryItem(icon: "fork.knife", value: "\(caloriesCount)", label: "餐次", color: .orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)  // 增加 padding 16 → 20
        .padding(.horizontal, 20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // 計算指定偏移量的日期範圍
    private func calculateDateRange(for offset: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimePeriod {
        case .day:
            let targetDate = calendar.date(byAdding: .day, value: offset, to: now)!
            let start = calendar.startOfDay(for: targetDate)
            let end = start.addingTimeInterval(24*60*60-1)
            return (start, end)
            
        case .week:
            let targetWeek = calendar.date(byAdding: .weekOfYear, value: offset, to: now)!
            let end = calendar.startOfDay(for: targetWeek).addingTimeInterval(24*60*60-1)
            let start = calendar.date(byAdding: .day, value: -6, to: end)!
            return (start, end)
            
        case .month:
            let targetMonth = calendar.date(byAdding: .month, value: offset, to: now)!
            let end = calendar.startOfDay(for: targetMonth).addingTimeInterval(24*60*60-1)
            let start = calendar.date(byAdding: .day, value: -29, to: end)!
            return (start, end)
        }
    }
    
    private func getRelativeTimeText(for offset: Int) -> String {
        switch selectedTimePeriod {
        case .day:
            if offset == 0 { return "今天" }
            else if offset == -1 { return "昨天" }
            else if offset == 1 { return "明天" }
            else if offset < 0 { return "\(abs(offset)) 天前" }
            else { return "\(offset) 天後" }
            
        case .week:
            if offset == 0 { return "本週" }
            else if offset == -1 { return "上週" }
            else if offset == 1 { return "下週" }
            else if offset < 0 { return "\(abs(offset)) 週前" }
            else { return "\(offset) 週後" }
            
        case .month:
            if offset == 0 { return "本月" }
            else if offset == -1 { return "上月" }
            else if offset == 1 { return "下月" }
            else if offset < 0 { return "\(abs(offset)) 月前" }
            else { return "\(offset) 月後" }
        }
    }
    
    private func getDateRangeText(for range: (start: Date, end: Date)) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        
        switch selectedTimePeriod {
        case .day:
            formatter.dateFormat = "M月d日 (E)"
            return formatter.string(from: range.start)
            
        case .week, .month:
            formatter.dateFormat = "M/d"
            let start = formatter.string(from: range.start)
            let end = formatter.string(from: range.end)
            return "\(start) - \(end)"
        }
    }
    
    private func calculateWorkoutsCount(for range: (start: Date, end: Date)) -> Int {
        return allWorkouts.filter { $0.timestamp >= range.start && $0.timestamp <= range.end }.count
    }
    
    private func calculateStepsCount(for range: (start: Date, end: Date)) -> String {
        let logs = allDailyLogs.filter { log in
            log.date >= range.start && log.date <= range.end
        }
        let total = logs.compactMap { $0.steps }.reduce(0, +)
        if total >= 10000 {
            return String(format: "%.1fk", Double(total) / 1000.0)
        } else {
            return "\(total)"
        }
    }
    
    private func calculateCaloriesCount(for range: (start: Date, end: Date)) -> Int {
        return allNutritionEntries.filter { $0.timestamp >= range.start && $0.timestamp <= range.end }.count
    }
    
    // MARK: - UI 組件
    
    private var emptyHealthDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("尚無健康數據")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("開始記錄每日數據來查看趨勢")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var timePeriodPicker: some View {
        Picker("時間週期", selection: $selectedTimePeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    private var muscleBalanceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("肌群均衡度").font(.headline)
                Spacer()
                Picker("指標", selection: $selectedMetric) {
                    ForEach(MuscleMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.menu)
            }
            
            let muscleData = calculateMuscleBalance()
            
            if !muscleData.isEmpty {
                Chart(muscleData) { item in
                    BarMark(
                        x: .value(selectedMetric.rawValue, item.value),
                        y: .value("肌群", item.muscleGroup.rawValue)
                    )
                    .foregroundStyle(colorForMuscle(item.muscleGroup))
                    .annotation(position: .trailing) {
                        Text(selectedMetric == .sets ? "\(Int(item.value))" : String(format: "%.0f", item.value))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: CGFloat(muscleData.count) * 50)
                .chartXAxis { AxisMarks(position: .bottom) }
                .chartYAxis { AxisMarks(position: .leading) { _ in AxisValueLabel() } }
            } else {
                Text("此期間無訓練數據").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var volumeTrendSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("訓練量趨勢").font(.headline)
            let trendData = calculateVolumeTrend()
            if !trendData.isEmpty {
                Chart(trendData) { item in
                    BarMark(
                        x: .value("日期", item.date, unit: selectedTimePeriod.calendarComponent),
                        y: .value("訓練量", item.volume)
                    )
                    .foregroundStyle(colorForMuscle(item.muscleGroup))
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .stride(by: selectedTimePeriod.calendarComponent, count: selectedTimePeriod.axisStride)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: selectedTimePeriod.dateFormat)
                    }
                }
                
                Divider().padding(.vertical, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(MuscleGroup.allCases.filter { $0 != .other }, id: \.self) { muscle in
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(colorForMuscle(muscle))
                                    .frame(width: 16, height: 16)
                                Text(muscle.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                Text("此期間無訓練數據").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var workoutSummarySection: some View {
        let filteredWorkouts = workouts
        let anaerobicWorkouts = filteredWorkouts.filter { $0.trainingType == .anaerobic }
        let totalVolume = anaerobicWorkouts.reduce(0.0) { $0 + $1.totalVolume }
        let totalSets = anaerobicWorkouts.reduce(0) { total, workout in
            total + workout.exerciseDetails.reduce(0) { $0 + $1.sets.count }
        }
        let avgVolume = anaerobicWorkouts.isEmpty ? 0 : totalVolume / Double(anaerobicWorkouts.count)
        let totalMinutes = filteredWorkouts.reduce(0) { $0 + $1.durationMinutes }
        
        return VStack(alignment: .leading, spacing: 15) {
            Text("訓練統計").font(.headline)
            VStack(spacing: 12) {
                StatRow(icon: "dumbbell.fill", label: "訓練次數", value: "\(filteredWorkouts.count) 次", color: .blue)
                StatRow(icon: "number", label: "總組數", value: "\(totalSets) 組", color: .green)
                StatRow(icon: "chart.bar.fill", label: "總訓練量", value: String(format: "%.0f kg", totalVolume), color: .orange)
                if !anaerobicWorkouts.isEmpty {
                    StatRow(icon: "chart.line.uptrend.xyaxis", label: "平均訓練量", value: String(format: "%.0f kg", avgVolume), color: .purple)
                }
                StatRow(icon: "clock.fill", label: "總時長", value: "\(totalMinutes) 分鐘", color: .red)
            }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(12).shadow(radius: 2).padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 60)).foregroundStyle(.secondary)
            Text("此期間無數據").font(.title3).foregroundStyle(.secondary)
            Text("開始記錄訓練和飲食數據").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    private var hasWorkoutData: Bool { !workouts.isEmpty }
    private var hasNutritionData: Bool { !nutritionEntries.isEmpty }
    
    private func calculateMuscleBalance() -> [MuscleBalanceData] {
        let filteredWorkouts = workouts
        var muscleStats: [MuscleGroup: (sets: Int, volume: Double)] = [:]
        for workout in filteredWorkouts where workout.trainingType == .anaerobic {
            for exercise in workout.exerciseDetails {
                let current = muscleStats[exercise.muscleGroup] ?? (sets: 0, volume: 0)
                muscleStats[exercise.muscleGroup] = (sets: current.sets + exercise.sets.count, volume: current.volume + exercise.totalVolume)
            }
        }
        return muscleStats
            .filter { $0.key != .other && $0.value.sets > 0 }
            .map { MuscleBalanceData(muscleGroup: $0.key, value: selectedMetric == .sets ? Double($0.value.sets) : $0.value.volume) }
            .sorted { $0.value > $1.value }
    }
    
    private func calculateVolumeTrend() -> [VolumeTrendData] {
        let filteredWorkouts = workouts
        var trendData: [VolumeTrendData] = []
        for workout in filteredWorkouts where workout.trainingType == .anaerobic {
            for exercise in workout.exerciseDetails {
                trendData.append(VolumeTrendData(date: workout.timestamp, muscleGroup: exercise.muscleGroup, volume: exercise.totalVolume))
            }
        }
        return trendData.sorted { $0.date < $1.date }
    }
    
    private func colorForMuscle(_ muscle: MuscleGroup) -> Color {
        switch muscle {
        case .chest:     return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .back:      return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .legs:      return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .shoulders: return Color(red: 0.7, green: 0.4, blue: 1.0)
        case .arms:      return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .core:      return Color(red: 1.0, green: 0.4, blue: 0.7)
        case .other:     return Color.gray
        }
    }
}

// MARK: - 摘要項目組件
struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 其他組件（保持不變）
// [健康數據輪播、圖表視圖等組件...]
// [為節省空間，這裡省略，與之前版本相同]

struct HealthMetricsCarousel: View {
    let logs: [DailyLog]
    @Binding var selectedTab: Int
    let timePeriod: TimePeriod
    
    private var dateRangeText: String {
        guard let firstLog = logs.first, let lastLog = logs.last else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M/d"
        
        let start = formatter.string(from: firstLog.date)
        let end = formatter.string(from: lastLog.date)
        
        if start == end {
            return start
        } else {
            return "\(start) - \(end)"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(["體重趨勢", "每日步數", "靜止心率", "睡眠時長"][selectedTab]).font(.title2).bold()
                Spacer()
                Text(dateRangeText).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            TabView(selection: $selectedTab) {
                WeightChartView(logs: logs, timePeriod: timePeriod).tag(0).padding(.horizontal)
                StepsChartView(logs: logs, timePeriod: timePeriod).tag(1).padding(.horizontal)
                HeartRateChartView(logs: logs, timePeriod: timePeriod).tag(2).padding(.horizontal)
                SleepChartView(logs: logs, timePeriod: timePeriod).tag(3).padding(.horizontal)
            }
            .frame(height: 300)
            .tabViewStyle(.page(indexDisplayMode: .never))
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(selectedTab == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .onTapGesture { withAnimation { selectedTab = index } }
                }
            }
            .padding(.vertical, 8)
            HealthSummaryCard(logs: logs, type: selectedTab).padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct HealthSummaryCard: View {
    let logs: [DailyLog]
    let type: Int
    var averageValue: String {
        switch type {
        case 0:
            let valid = logs.compactMap { $0.weight }
            return valid.isEmpty ? "--" : String(format: "%.1f kg", valid.reduce(0, +) / Double(valid.count))
        case 1:
            let valid = logs.compactMap { $0.steps }
            return valid.isEmpty ? "--" : String(format: "%.0f 步", Double(valid.reduce(0, +)) / Double(valid.count))
        case 2:
            let valid = logs.compactMap { $0.restingHeartRate }
            return valid.isEmpty ? "--" : String(format: "%.0f BPM", Double(valid.reduce(0, +)) / Double(valid.count))
        case 3:
            let valid = logs.compactMap { $0.sleepDurationHours }
            return valid.isEmpty ? "--" : String(format: "%.1f 小時", valid.reduce(0, +) / Double(valid.count))
        default: return "--"
        }
    }
    var maxLog: (date: Date, value: String)? {
        switch type {
        case 0:
            guard let max = logs.compactMap({ l in l.weight.map { (l.date, $0) } }).max(by: { $0.1 < $1.1 }) else { return nil }
            return (max.0, String(format: "%.1f kg", max.1))
        case 1:
            guard let max = logs.compactMap({ l in l.steps.map { (l.date, $0) } }).max(by: { $0.1 < $1.1 }) else { return nil }
            return (max.0, "\(max.1) 步")
        case 2:
            guard let max = logs.compactMap({ l in l.restingHeartRate.map { (l.date, $0) } }).max(by: { $0.1 < $1.1 }) else { return nil }
            return (max.0, "\(max.1) BPM")
        case 3:
            guard let max = logs.compactMap({ l in l.sleepDurationHours.map { (l.date, $0) } }).max(by: { $0.1 < $1.1 }) else { return nil }
            return (max.0, String(format: "%.1f 小時", max.1))
        default: return nil
        }
    }
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("平均數值").font(.caption).foregroundStyle(.secondary)
                Text(averageValue).font(.title2).bold().foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding().background(Color(.systemBackground)).cornerRadius(12).shadow(radius: 2)
            if let max = maxLog {
                VStack(alignment: .leading) {
                    Text("最高 (\(max.date.formatted(.dateTime.month().day())))").font(.caption).foregroundStyle(.secondary)
                    Text(max.value).font(.title2).bold().foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding().background(Color(.systemBackground)).cornerRadius(12).shadow(radius: 2)
            }
        }
    }
}

struct OptimizedDateAxisLabel: View {
    let date: Date; let allDates: [Date]; let currentIndex: Int
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(date.formatted(.dateTime.day())).font(.caption2)
            if shouldShowMonth {
                Text(date.formatted(.dateTime.month(.abbreviated))).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
    private var shouldShowMonth: Bool {
        if currentIndex == 0 { return true }
        if currentIndex > 0 {
            let calendar = Calendar.current
            return calendar.component(.month, from: date) != calendar.component(.month, from: allDates[currentIndex - 1])
        }
        return false
    }
}

struct WeightChartView: View {
    let logs: [DailyLog]
    let timePeriod: TimePeriod
    
    var body: some View {
        let dates = logs.map { $0.date }
        return Chart {
            ForEach(Array(logs.enumerated()), id: \.element.id) { index, log in
                if let weight = log.weight {
                    LineMark(x: .value("日期", log.date, unit: timePeriod.calendarComponent), y: .value("體重", weight))
                        .foregroundStyle(.blue).interpolationMethod(.catmullRom)
                        .symbol { Circle().fill(.blue).frame(width: 6, height: 6) }
                    AreaMark(x: .value("日期", log.date, unit: timePeriod.calendarComponent), y: .value("體重", weight))
                        .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .stride(by: timePeriod.calendarComponent, count: timePeriod.axisStride)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        if timePeriod == .day {
                            if let index = dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
                                OptimizedDateAxisLabel(date: date, allDates: dates, currentIndex: index)
                            }
                        } else {
                            Text(date, format: timePeriod.dateFormat)
                        }
                    }
                }
            }
        }
    }
}

struct StepsChartView: View {
    let logs: [DailyLog]
    let timePeriod: TimePeriod
    
    var body: some View {
        let dates = logs.map { $0.date }
        return Chart {
            ForEach(logs) { log in
                if let steps = log.steps {
                    BarMark(x: .value("日期", log.date, unit: timePeriod.calendarComponent), y: .value("步數", steps))
                        .foregroundStyle(.green.gradient).cornerRadius(4)
                }
            }
            RuleMark(y: .value("目標", 8000)).lineStyle(StrokeStyle(lineWidth: 1, dash: [5])).foregroundStyle(.gray.opacity(0.5))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: timePeriod.calendarComponent, count: timePeriod.axisStride)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        if timePeriod == .day {
                            if let index = dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
                                OptimizedDateAxisLabel(date: date, allDates: dates, currentIndex: index)
                            }
                        } else {
                            Text(date, format: timePeriod.dateFormat)
                        }
                    }
                }
            }
        }
    }
}

struct HeartRateChartView: View {
    let logs: [DailyLog]
    let timePeriod: TimePeriod
    
    var body: some View {
        let dates = logs.map { $0.date }
        return Chart {
            ForEach(logs) { log in
                if let hr = log.restingHeartRate {
                    LineMark(x: .value("日期", log.date, unit: timePeriod.calendarComponent), y: .value("心率", hr))
                        .foregroundStyle(.red).interpolationMethod(.catmullRom)
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .stride(by: timePeriod.calendarComponent, count: timePeriod.axisStride)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        if timePeriod == .day {
                            if let index = dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
                                OptimizedDateAxisLabel(date: date, allDates: dates, currentIndex: index)
                            }
                        } else {
                            Text(date, format: timePeriod.dateFormat)
                        }
                    }
                }
            }
        }
    }
}

struct SleepChartView: View {
    let logs: [DailyLog]
    let timePeriod: TimePeriod
    
    var body: some View {
        let dates = logs.map { $0.date }
        return Chart {
            ForEach(logs) { log in
                if let sleep = log.sleepDurationHours {
                    BarMark(x: .value("日期", log.date, unit: timePeriod.calendarComponent), y: .value("小時", sleep))
                        .foregroundStyle(.indigo.gradient).cornerRadius(4)
                }
            }
            RuleMark(y: .value("基準", 7)).lineStyle(StrokeStyle(lineWidth: 1, dash: [5])).foregroundStyle(.orange)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: timePeriod.calendarComponent, count: timePeriod.axisStride)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        if timePeriod == .day {
                            if let index = dates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
                                OptimizedDateAxisLabel(date: date, allDates: dates, currentIndex: index)
                            }
                        } else {
                            Text(date, format: timePeriod.dateFormat)
                        }
                    }
                }
            }
        }
    }
}

enum TimePeriod: String, CaseIterable {
    case day = "日", week = "週", month = "月"
    var calendarComponent: Calendar.Component { self == .day ? .hour : .day }
    var axisStride: Int { self == .month ? 5 : 1 }
    var dateFormat: Date.FormatStyle { self == .day ? .dateTime.hour() : (self == .week ? .dateTime.weekday(.abbreviated) : .dateTime.month().day()) }
}

enum MuscleMetric: String, CaseIterable { case sets = "組數", volume = "訓練量(kg)" }
struct MuscleBalanceData: Identifiable { let id = UUID(); let muscleGroup: MuscleGroup; let value: Double }
struct VolumeTrendData: Identifiable { let id = UUID(); let date: Date; let muscleGroup: MuscleGroup; let volume: Double }
struct StatRow: View {
    let icon: String; let label: String; let value: String; let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 30)
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct NutritionAnalyticsSection: View {
    let entries: [NutritionEntry]
    let timePeriod: TimePeriod
    struct MacroData: Identifiable { let id = UUID(); let type: MacroType; let totalPortions: Double }
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("飲食結構分析").font(.headline)
            let data = calculateMacroData()
            if !data.isEmpty {
                Chart(data) { item in
                    BarMark(x: .value("份數", item.totalPortions), y: .value("類別", "總攝取"))
                        .foregroundStyle(colorForMacro(item.type))
                }
                .frame(height: 60)
                Divider()
                LazyVGrid(columns: columns, spacing: 15) {
                    if let p = data.first(where: { $0.type == .protein }) { MacroStatItem(title: "蛋白質", value: String(format: "%.1f", p.totalPortions), unit: "掌", color: .red) }
                    if let c = data.first(where: { $0.type == .carbs }) { MacroStatItem(title: "碳水", value: String(format: "%.1f", c.totalPortions), unit: "捧", color: .orange) }
                    if let v = data.first(where: { $0.type == .vegetables }) { MacroStatItem(title: "蔬菜", value: String(format: "%.1f", v.totalPortions), unit: "拳", color: .green) }
                    if let f = data.first(where: { $0.type == .fats }) { MacroStatItem(title: "油脂", value: String(format: "%.1f", f.totalPortions), unit: "指", color: .yellow) }
                }
            } else { Text("此期間無飲食紀錄").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding() }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(12).shadow(radius: 2).padding(.horizontal)
    }
    private func calculateMacroData() -> [MacroData] {
        var p = 0.0, c = 0.0, v = 0.0, f = 0.0
        for e in entries { p += e.proteinPortions ?? 0; c += e.carbPortions ?? 0; v += e.vegPortions ?? 0; f += e.fatPortions ?? 0 }
        return [MacroData(type: .protein, totalPortions: p), MacroData(type: .carbs, totalPortions: c), MacroData(type: .vegetables, totalPortions: v), MacroData(type: .fats, totalPortions: f)].filter { $0.totalPortions > 0 }
    }
    private func colorForMacro(_ type: MacroType) -> Color {
        switch type { case .protein: return .red; case .carbs: return .orange; case .vegetables: return .green; case .fats: return .yellow }
    }
}

struct MacroStatItem: View {
    let title: String; let value: String; let unit: String; let color: Color
    var body: some View { VStack(alignment: .leading, spacing: 4) { Text(title).font(.caption).foregroundStyle(.secondary); HStack(alignment: .bottom, spacing: 2) { Text(value).font(.headline).foregroundStyle(color); Text(unit).font(.caption2).foregroundStyle(.secondary).offset(y: -2) } } }
}
