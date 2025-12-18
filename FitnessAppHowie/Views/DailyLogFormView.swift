//
//  DailyLogFormView.swift
//  Howie's Fitness Log
//
//  每日數據記錄表單 - 支援睡眠時數自動計算
//

import SwiftUI
import SwiftData

struct DailyLogFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let existingLog: DailyLog?
    
    @State private var date = Date()
    @State private var weight: String = ""
    @State private var sleepDuration: String = ""
    
    // 預設起床時間 07:00, 睡覺時間 23:00 (為了方便選擇)
    @State private var wakeUpTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var sleepTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    
    @State private var steps: String = ""
    @State private var restingHeartRate: String = ""
    
    init(existingLog: DailyLog? = nil) {
        self.existingLog = existingLog
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("日期") {
                    DatePicker("記錄日期", selection: $date, displayedComponents: .date)
                }
                
                Section("體重") {
                    HStack {
                        TextField("體重", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("睡眠") {
                    // MARK: - 修改 1: 加上 onChange 監聽時間變化
                    DatePicker("睡覺時間", selection: $sleepTime, displayedComponents: .hourAndMinute)
                        .onChange(of: sleepTime) { calculateSleepDuration() }
                    
                    DatePicker("起床時間", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                        .onChange(of: wakeUpTime) { calculateSleepDuration() }
                    
                    HStack {
                        Text("總睡眠時長")
                        Spacer()
                        // 這裡依然允許手動修改，但通常會自動算好
                        TextField("自動計算", text: $sleepDuration)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("小時")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("活動") {
                    HStack {
                        TextField("步數", text: $steps)
                            .keyboardType(.numberPad)
                        Text("步")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("心率") {
                    HStack {
                        TextField("靜止心率", text: $restingHeartRate)
                            .keyboardType(.numberPad)
                        Text("BPM")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(existingLog == nil ? "新增每日數據" : "編輯每日數據")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        saveLog()
                    }
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    // MARK: - 修改 2: 自動計算邏輯
    private func calculateSleepDuration() {
        let calendar = Calendar.current
        
        // 為了只比較「時間」，我們把日期都統一設為今天，避免 DatePicker 自帶的日期干擾
        let now = Date()
        let sleepComps = calendar.dateComponents([.hour, .minute], from: sleepTime)
        let wakeComps = calendar.dateComponents([.hour, .minute], from: wakeUpTime)
        
        guard let sTime = calendar.date(bySettingHour: sleepComps.hour!, minute: sleepComps.minute!, second: 0, of: now),
              let wTime = calendar.date(bySettingHour: wakeComps.hour!, minute: wakeComps.minute!, second: 0, of: now) else { return }
        
        // 計算差距 (秒)
        var diff = wTime.timeIntervalSince(sTime)
        
        // 處理跨日：如果起床時間比睡覺時間早 (例如 07:00 < 23:00)，代表跨了一天，加 24 小時
        if diff < 0 {
            diff += 86400 // 24小時 * 60分 * 60秒
        }
        
        let hours = diff / 3600
        sleepDuration = String(format: "%.1f", hours)
    }
    
    private func loadExistingData() {
        if let log = existingLog {
            date = log.date
            if let w = log.weight { weight = String(w) }
            if let sd = log.sleepDurationHours { sleepDuration = String(sd) }
            if let wt = log.wakeUpTime { wakeUpTime = wt }
            if let st = log.sleepTime { sleepTime = st }
            if let s = log.steps { steps = String(s) }
            if let hr = log.restingHeartRate { restingHeartRate = String(hr) }
        } else {
            // 如果是新增模式，一進來就算一次預設值的時差
            calculateSleepDuration()
        }
    }
    
    private func saveLog() {
        let log = existingLog ?? DailyLog(date: date)
        
        log.date = Calendar.current.startOfDay(for: date)
        log.weight = Double(weight)
        log.sleepDurationHours = Double(sleepDuration)
        log.wakeUpTime = wakeUpTime
        log.sleepTime = sleepTime
        log.steps = Int(steps)
        log.restingHeartRate = Int(restingHeartRate)
        
        if existingLog == nil {
            modelContext.insert(log)
        }
        
        dismiss()
    }
}

#Preview {
    DailyLogFormView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
