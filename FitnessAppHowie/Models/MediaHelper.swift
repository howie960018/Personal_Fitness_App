//
//  MediaHelper.swift
//  FitHowie
//
//  處理照片與影片的儲存邏輯
//

import SwiftUI
import PhotosUI

struct MediaHelper {
    /// 儲存照片或影片資料到 Documents
    /// - Returns: 儲存後的檔名
    static func saveMedia(data: Data, extensionName: String) -> String? {
        let filename = "\(UUID().uuidString).\(extensionName)"
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            print("儲存媒體失敗: \(error)")
            return nil
        }
    }
    
    /// 刪除舊檔案
    static func deleteMedia(filename: String?) {
        guard let filename = filename,
              let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsPath.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
