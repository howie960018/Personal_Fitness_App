//
//  DailyLog.swift
//  Howie's Fitness Log
//
//  每日數據紀錄模型
//

import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var date: Date
    var weight: Double?
    var sleepDurationHours: Double?
    var wakeUpTime: Date?
    var sleepTime: Date?
    var steps: Int?
    var restingHeartRate: Int?
    
    init(
        date: Date = Date(),
        weight: Double? = nil,
        sleepDurationHours: Double? = nil,
        wakeUpTime: Date? = nil,
        sleepTime: Date? = nil,
        steps: Int? = nil,
        restingHeartRate: Int? = nil
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.weight = weight
        self.sleepDurationHours = sleepDurationHours
        self.wakeUpTime = wakeUpTime
        self.sleepTime = sleepTime
        self.steps = steps
        self.restingHeartRate = restingHeartRate
    }
}
