//
//  AnalyticsView.swift
//  FitHowie
//
//  分析視圖 - 修正 Enum 重複宣告問題
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - 資料查詢
    // 1. 每日數據 (給頂部新功能：健康輪播圖用) - 依日期舊到新排序
    @Query(sort: \DailyLog.date, order: .forward) private var allDailyLogs: [DailyLog]
    
    // 2. 訓練記錄 (給原有功能用) - 依日期新到舊
    @Query(sort: \WorkoutRecord.timestamp, order: .reverse) private var workouts: [WorkoutRecord]
    
    // 3. 飲食記錄 (給原有功能用) - 依日期新到舊
    @Query(sort: \NutritionEntry.timestamp, order: .reverse) private var nutritionEntries: [NutritionEntry]
    
    // MARK: - 狀態變數
    @State private var selectedTimePeriod: TimePeriod = .week
    @State private var selectedMetric: MuscleMetric = .sets
    @State private var selectedChartTab = 0 // 控制頂部輪播圖的分頁
    
    // 取得最近 30 天的每日數據 (給頂部圖表用)
    var recentLogs: [DailyLog] {
        allDailyLogs.suffix(30)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: 1. 健康數據輪播 (體重/步數/心率/睡眠)
                    if !recentLogs.isEmpty {
                        HealthMetricsCarousel(
                            logs: recentLogs,
                            selectedTab: $selectedChartTab
                        )
                        .padding(.horizontal)
                    }
                    
                    // 分隔線
                    Divider().padding(.vertical, 5)

                    // MARK: 2. 時間週期選擇器
                    timePeriodPicker
                    
                    // MARK: 3. 飲食分析
                    if hasNutritionData {
                        NutritionAnalyticsSection(
                            entries: nutritionEntries,
                            timePeriod: selectedTimePeriod
                        )
                    }
                    
                    // MARK: 4. 訓練數據分析
                    if hasWorkoutData {
                        // A. 肌群均衡度分析
                        muscleBalanceSection
                        
                        // B. 訓練量趨勢
                        volumeTrendSection
                        
                        // C. 訓練統計摘要
                        workoutSummarySection
                    }
                    
                    // MARK: 5. 空狀態
                    if !hasWorkoutData && !hasNutritionData && recentLogs.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("數據分析")
        }
    }
    
    // MARK: - UI 組件
    
    private var timePeriodPicker: some View {
        Picker("時間週期", selection: $selectedTimePeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    // A. 肌群均衡度
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
                    .foregroundStyle(by: .value("肌群", item.muscleGroup.rawValue))
                    .annotation(position: .trailing) {
                        Text(selectedMetric == .sets ? "\(Int(item.value))" : String(format: "%.0f", item.value))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartLegend(.hidden)
                .frame(height: CGFloat(muscleData.count) * 50)
                .chartXAxis { AxisMarks(position: .bottom) }
                .chartYAxis { AxisMarks(position: .leading) { _ in AxisValueLabel() } }
            } else {
                Text("此期間無訓練數據").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding()
            }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(12).shadow(radius: 2).padding(.horizontal)
    }
    
    // B. 訓練量趨勢
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
                    .foregroundStyle(by: .value("肌群", item.muscleGroup.rawValue))
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .stride(by: selectedTimePeriod.calendarComponent, count: selectedTimePeriod.axisStride)) { _ in
                        AxisGridLine(); AxisValueLabel(format: selectedTimePeriod.dateFormat)
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MuscleGroup.allCases.filter { $0 != .other }, id: \.self) { muscle in
                                HStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 2).fill(colorForMuscle(muscle)).frame(width: 12, height: 12)
                                    // MARK: - 修改 1: 將圖例文字顏色改為灰色
                                    Text(muscle.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("此期間無訓練數據").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding()
            }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(12).shadow(radius: 2).padding(.horizontal)
    }
    
    // C. 訓練統計摘要
    private var workoutSummarySection: some View {
        let filteredWorkouts = getFilteredWorkouts()
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
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 60)).foregroundStyle(.secondary)
            Text("尚無數據可分析").font(.title3).foregroundStyle(.secondary)
            Text("開始記錄訓練和每日數據來查看分析").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding().frame(maxHeight: .infinity)
    }
    
    // MARK: - 邏輯運算 (Helpers)
    
    private var hasWorkoutData: Bool { !getFilteredWorkouts().isEmpty }
    private var hasNutritionData: Bool {
        let dateRange = selectedTimePeriod.dateRange
        return nutritionEntries.contains { $0.timestamp >= dateRange.start && $0.timestamp <= dateRange.end }
    }
    
    private func getFilteredWorkouts() -> [WorkoutRecord] {
        let dateRange = selectedTimePeriod.dateRange
        return workouts.filter { $0.timestamp >= dateRange.start && $0.timestamp <= dateRange.end }
    }
    
    private func calculateMuscleBalance() -> [MuscleBalanceData] {
        let filteredWorkouts = getFilteredWorkouts()
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
        let filteredWorkouts = getFilteredWorkouts()
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
        case .chest: return .blue; case .back: return .green; case .legs: return .orange
        case .shoulders: return .purple; case .arms: return .red; case .core: return .pink; case .other: return .gray
        }
    }
}

// =========================================
// MARK: - 健康數據輪播組件
// =========================================

struct HealthMetricsCarousel: View {
    let logs: [DailyLog]
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // 標題與分頁
            HStack {
                Text(chartTitle)
                    .font(.title2)
                    .bold()
                Spacer()
                Text("最近 30 天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            // 滑動區域
            TabView(selection: $selectedTab) {
                WeightChartView(logs: logs).tag(0).padding(.horizontal)
                StepsChartView(logs: logs).tag(1).padding(.horizontal)
                HeartRateChartView(logs: logs).tag(2).padding(.horizontal)
                SleepChartView(logs: logs).tag(3).padding(.horizontal)
            }
            .frame(height: 300)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // 數據摘要
            HealthSummaryCard(logs: logs, type: selectedTab)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var chartTitle: String {
        switch selectedTab {
        case 0: return "體重趨勢"
        case 1: return "每日步數"
        case 2: return "靜止心率"
        case 3: return "睡眠時長"
        default: return ""
        }
    }
}

// 健康數據摘要卡片
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

// 4種圖表視圖
struct WeightChartView: View {
    let logs: [DailyLog]
    var body: some View {
        Chart {
            ForEach(logs) { log in
                if let weight = log.weight {
                    LineMark(x: .value("日期", log.date, unit: .day), y: .value("體重", weight))
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                        .symbol { Circle().fill(.blue).frame(width: 6, height: 6) }
                    AreaMark(x: .value("日期", log.date, unit: .day), y: .value("體重", weight))
                        .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .blue.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis { AxisMarks(values: .stride(by: .day, count: 5)) { _ in AxisValueLabel(format: .dateTime.month().day()) } }
    }
}

struct StepsChartView: View {
    let logs: [DailyLog]
    var body: some View {
        Chart {
            ForEach(logs) { log in
                if let steps = log.steps {
                    BarMark(x: .value("日期", log.date, unit: .day), y: .value("步數", steps))
                        .foregroundStyle(.green.gradient).cornerRadius(4)
                }
            }
            RuleMark(y: .value("目標", 8000))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5])).foregroundStyle(.gray.opacity(0.5))
        }
        .chartXAxis { AxisMarks(values: .stride(by: .day, count: 5)) { _ in AxisValueLabel(format: .dateTime.month().day()) } }
    }
}

struct HeartRateChartView: View {
    let logs: [DailyLog]
    var body: some View {
        Chart {
            ForEach(logs) { log in
                if let hr = log.restingHeartRate {
                    LineMark(x: .value("日期", log.date, unit: .day), y: .value("心率", hr))
                        .foregroundStyle(.red).interpolationMethod(.catmullRom).symbol(by: .value("Type", "BPM"))
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis { AxisMarks(values: .stride(by: .day, count: 5)) { _ in AxisValueLabel(format: .dateTime.month().day()) } }
    }
}

struct SleepChartView: View {
    let logs: [DailyLog]
    var body: some View {
        Chart {
            ForEach(logs) { log in
                if let sleep = log.sleepDurationHours {
                    BarMark(x: .value("日期", log.date, unit: .day), y: .value("小時", sleep))
                        .foregroundStyle(.indigo.gradient).cornerRadius(4)
                }
            }
            RuleMark(y: .value("基準", 7)).lineStyle(StrokeStyle(lineWidth: 1, dash: [5])).foregroundStyle(.orange)
        }
        .chartXAxis { AxisMarks(values: .stride(by: .day, count: 5)) { _ in AxisValueLabel(format: .dateTime.month().day()) } }
    }
}


// =========================================
// MARK: - 輔助型別 (Structs & Local Enums)
// 注意：MacroType 已移除，改用全局 Enums.swift 定義
// =========================================

enum TimePeriod: String, CaseIterable {
    case day = "日", week = "周", month = "月"
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current, now = Date()
        let end = calendar.startOfDay(for: now).addingTimeInterval(24*60*60-1)
        switch self {
        case .day: return (calendar.startOfDay(for: now), end)
        case .week: return (calendar.date(byAdding: .day, value: -6, to: end)!, end)
        case .month: return (calendar.date(byAdding: .day, value: -29, to: end)!, end)
        }
    }
    var calendarComponent: Calendar.Component { self == .day ? .hour : .day }
    var axisStride: Int { self == .month ? 5 : 1 }
    var dateFormat: Date.FormatStyle { self == .day ? .dateTime.hour() : (self == .week ? .dateTime.weekday(.abbreviated) : .dateTime.month().day()) }
}

enum MuscleMetric: String, CaseIterable { case sets = "組數", volume = "訓練量(kg)" }

// 這些 Struct 專屬於圖表使用，所以放在這裡
struct MuscleBalanceData: Identifiable { let id = UUID(); let muscleGroup: MuscleGroup; let value: Double }
struct VolumeTrendData: Identifiable { let id = UUID(); let date: Date; let muscleGroup: MuscleGroup; let volume: Double }

// 訓練統計行
struct StatRow: View {
    let icon: String; let label: String; let value: String; let color: Color
    var body: some View {
        HStack {
            // Icon 保持傳入的顏色 (color)
            Image(systemName: icon).foregroundStyle(color).frame(width: 30);
            Text(label).foregroundStyle(.secondary);
            Spacer();
            // MARK: - 修改 2: 數值統一顯示為藍色
            Text(value).fontWeight(.semibold).foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}

// =========================================
// MARK: - 飲食分析組件
// =========================================

struct NutritionAnalyticsSection: View {
    let entries: [NutritionEntry]
    let timePeriod: TimePeriod
    
    // 使用全局的 MacroType
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
                        .annotation(position: .overlay) { if item.totalPortions > 0.5 { Text(String(format: "%.1f", item.totalPortions)).font(.caption2).foregroundColor(.white).shadow(radius: 1) } }
                }
                .frame(height: 60)
                .chartXAxis { AxisMarks(position: .bottom) { _ in AxisValueLabel(); AxisGridLine() } }
                .chartYAxis(.hidden)
                Divider()
                LazyVGrid(columns: columns, spacing: 15) {
                    if let p = data.first(where: { $0.type == .protein }) { MacroStatItem(title: "蛋白質", value: String(format: "%.1f", p.totalPortions), unit: "掌", color: .red) }
                    if let c = data.first(where: { $0.type == .carbs }) { MacroStatItem(title: "碳水", value: String(format: "%.1f", c.totalPortions), unit: "捧", color: .orange) }
                    if let v = data.first(where: { $0.type == .vegetables }) { MacroStatItem(title: "蔬菜", value: String(format: "%.1f", v.totalPortions), unit: "拳", color: .green) }
                    if let f = data.first(where: { $0.type == .fats }) { MacroStatItem(title: "油脂", value: String(format: "%.1f", f.totalPortions), unit: "指", color: .yellow) }
                }
                .padding(.top, 5)
            } else { Text("此期間無飲食紀錄").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding() }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(12).shadow(radius: 2).padding(.horizontal)
    }
    
    private func calculateMacroData() -> [MacroData] {
        let dateRange = timePeriod.dateRange
        let filtered = entries.filter { $0.timestamp >= dateRange.start && $0.timestamp <= dateRange.end }
        var p = 0.0, c = 0.0, v = 0.0, f = 0.0
        for e in filtered { p += e.proteinPortions ?? 0; c += e.carbPortions ?? 0; v += e.vegPortions ?? 0; f += e.fatPortions ?? 0 }
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
