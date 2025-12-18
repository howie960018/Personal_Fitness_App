//
//  DailyLogFormView.swift
//  Howie's Fitness Log
//
//  每日數據記錄表單
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
    @State private var wakeUpTime = Date()
    @State private var sleepTime = Date()
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
                    HStack {
                        TextField("總睡眠時長", text: $sleepDuration)
                            .keyboardType(.decimalPad)
                        Text("小時")
                            .foregroundStyle(.secondary)
                    }
                    
                    DatePicker("起床時間", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                    DatePicker("睡覺時間", selection: $sleepTime, displayedComponents: .hourAndMinute)
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
    
    private func loadExistingData() {
        if let log = existingLog {
            date = log.date
            if let w = log.weight { weight = String(w) }
            if let sd = log.sleepDurationHours { sleepDuration = String(sd) }
            if let wt = log.wakeUpTime { wakeUpTime = wt }
            if let st = log.sleepTime { sleepTime = st }
            if let s = log.steps { steps = String(s) }
            if let hr = log.restingHeartRate { restingHeartRate = String(hr) }
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
