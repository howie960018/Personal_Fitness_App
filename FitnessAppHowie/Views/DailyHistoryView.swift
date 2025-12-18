import SwiftUI
import SwiftData

struct DailyHistoryView: View {
    // 1. 核心查詢：自動抓取所有 DailyLog，並按日期「從新到舊」排列
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]
    
    // 用來觸發編輯頁面
    @State private var selectedLog: DailyLog?
    @State private var isShowingEditSheet = false

    var body: some View {
        NavigationStack {
            List {
                // 如果今天還沒紀錄，顯示一個快速按鈕 (UX 優化)
                if !isTodayLogged {
                    Section {
                        Button {
                            createNewLog()
                        } label: {
                            Label("紀錄今天的數據", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                    }
                }
                
                // 2. 歷史數據列表
                Section(header: Text("歷史紀錄")) {
                    ForEach(logs) { log in
                        DailyLogCard(log: log)
                            .contentShape(Rectangle()) // 讓整個區域可點擊
                            .onTapGesture {
                                selectedLog = log
                                isShowingEditSheet = true
                            }
                    }
                    .onDelete(perform: deleteLog) // 支援左滑刪除
                }
            }
            .navigationTitle("每日身體數據")
            .sheet(item: $selectedLog) { log in
                // 這裡放你的編輯/新增頁面，例如 DailyLogEditorView(log: log)
                Text("編輯頁面: \(log.date.formatted())")
                    .presentationDetents([.medium])
            }
        }
    }
    
    // 判斷最新的紀錄是不是今天
    var isTodayLogged: Bool {
        guard let firstLog = logs.first else { return false }
        return Calendar.current.isDateInToday(firstLog.date)
    }
    
    // 刪除功能
    func deleteLog(at offsets: IndexSet) {
        // SwiftData 的刪除邏輯
        // modelContext.delete(logs[index])
    }
    
    // 建立新紀錄邏輯
    func createNewLog() {
        // logic to create new DailyLog for today
    }
}

// 3. 單日數據卡片 UI
struct DailyLogCard: View {
    let log: DailyLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日期標題 (e.g., 今天, 昨天, 12月16日 週六)
            Text(formatDate(log.date))
                .font(.headline)
                .foregroundStyle(.blue)
            
            HStack(spacing: 20) {
                // 體重
                DataCell(icon: "scalemass", value: "\(log.weight)", unit: "kg")
                
                // 步數
                DataCell(icon: "figure.walk", value: "\(log.steps)", unit: "步")
                
                // 睡眠
                DataCell(icon: "bed.double", value: "\(log.sleepDurationHours)", unit: "hr")
            }
        }
        .padding(.vertical, 4)
    }
    
    // 智能日期格式化 helper
    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            // 自訂格式：12/18 (週四)
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d (EE)"
            formatter.locale = Locale(identifier: "zh_TW")
            return formatter.string(from: date)
        }
    }
}

// 小元件：數據單元格
struct DataCell: View {
    let icon: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            
            // 如果數值是 0，顯示 "--" 比較好看
            Text((Double(value) ?? 0) > 0 ? value : "--")
                .bold()
            
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    DailyHistoryView()
}
